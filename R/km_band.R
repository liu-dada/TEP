#' KM + Band Plot with Shared X-axis and Fixed Colors
#'
#' Combines a Kaplan–Meier survival plot (`km_plot`) with a corresponding band plot
#' (`band_plot`) aligned on a shared x-axis. Control and treatment groups are
#' colored black and red, respectively. Automatically adds log-rank and
#' Wang–Allison (2004) p-values based on survival percentiles.
#'
#' @param km_plot A ggplot object representing the Kaplan–Meier survival curve.
#' @param band_plot A ggplot object for the band plot. If `NULL`, a placeholder
#'   plot with "no significant interval" is created.
#' @param data Data frame containing at least columns `age`, `dead`, and `group`.
#' @param xlab Label for the x-axis (default `"Age (Days)"`).
#' @param heights Numeric vector of length 2 specifying relative heights of the
#'   KM and band plots (default `c(3, 0.34)`).
#' @param pad_km Numeric vector of length 4 specifying plot margins (top, right, bottom, left)
#'   for the KM pane (default `c(4, 6, 0, 6)`).
#' @param pad_bn Numeric vector of length 4 specifying plot margins (top, right, bottom, left)
#'   for the band pane (default `c(0, 6, 4, 2)`).
#' @param band_y Y-axis location for the band plot annotation (default `3`).
#' @param wa_percentile Numeric between 0 and 1 specifying the survival percentile
#'   used for the Wang–Allison p-value (default `0.90` for the 90th percentile).
#' @param ctrl_name Character string specifying the name of the control group (default `"WT"`).
#' @param treat_name Character string specifying the name of the treatment group (default `"KO"`).
#' @importFrom ggplot2 ggplot labs scale_color_manual scale_fill_manual
#' @importFrom ggplot2 scale_x_continuous scale_y_continuous annotate theme theme_classic
#' @importFrom grid unit
#' @importFrom stats setNames
#' @importFrom survival survfit Surv
#' @importFrom patchwork plot_layout
#'
#' @return A `patchwork` object combining the KM plot and the band plot, with:
#'   - Kaplan–Meier survival curve in the top pane,
#'   - Band plot (or placeholder) in the bottom pane,
#'   - Log-rank and Wang–Allison p-values annotated on the KM plot.
#'
#' @details
#' The function automatically extracts strata names from `km_plot$data` to lock colors:
#' black for control, red for treatment. The Wang–Allison p-value is computed using
#' a Fisher exact test at the specified survival percentile.
#'
#' @examples
#' library(survival)
#' library(ggplot2)
#'
#' boot_hr <- bshr(data=example_data, contr = "Control", var = "GTE", n_boot = 100)
#' p <- band_func(data1 = example_data, data2 = boot_hr, lim0 = 0, lim1 = 1500, var = "GTE")
#'
#' km_plot <- survminer::ggsurvplot(
#'   survfit(Surv(age, dead) ~ group, data = example_data),
#'   data = example_data,
#'   palette = c("black", "red"),
#'   risk.table = FALSE
#' )$plot
#'
#' make_km_band(km_plot, band_plot = p, data = example_data)
#'
#' @export
# ==============================================================================
# KM + Band (shared x-axis) with fixed colors (ctrl = black, treat = red)
# ==============================================================================
make_km_band <- function(km_plot, band_plot, data,
                         xlab = "Age (Days)", heights = c(3, 0.34),
                         pad_km = c(4, 6, 0, 6), pad_bn = c(0, 6, 4, 2),
                         band_y = 3,
                         wa_percentile = 0.90,
                         ctrl_name = "Control",
                         treat_name = "GTE") {

  xmin  <- 0
  xmax  <- max(data$age, na.rm = TRUE)
  xspan <- xmax - xmin

  # ---- log-rank p-value ----
  lr_p <- tryCatch({
    sdiff <- survival::survdiff(survival::Surv(age, dead) ~ group, data = data)
    stats::pchisq(sdiff$chisq, df = length(sdiff$n) - 1, lower.tail = FALSE)
  }, error = function(e) NA_real_)
  pval_lab <- if (is.na(lr_p)) "Log-rank pval: NA"
  else paste0("Log-rank pval: ", format.pval(lr_p, digits = 3, eps = 1e-4))

  # positions (bottom-left)
  p_x     <- xmin + 0.05 * xspan
  p_y_top <- 0.20
  p_y_wa  <- max(0.02, p_y_top - 0.07)

  # ---- Wang–Allison p-value (Fisher test at pooled KM percentile) ----
  wa_label <- tryCatch({
    grps <- sort(unique(as.character(data$group)))
    if (length(grps) != 2) stop("Need exactly 2 groups for WA test.")
    fit <- survival::survfit(survival::Surv(age, dead) ~ 1,
                             data = data[data$group %in% grps, , drop = FALSE])
    sf  <- data.frame(time = fit$time, surv = fit$surv)
    thr <- sf$time[which(sf$surv <= (1 - wa_percentile))[1]]
    if (!is.finite(thr)) stop("Percentile threshold not reached.")
    d2 <- data[data$group %in% grps, c("group", "age")]
    d2$to_thr <- d2$age >= thr
    tab <- table(factor(d2$group, levels = grps), d2$to_thr)
    if (!"FALSE" %in% colnames(tab)) tab <- cbind(tab, `FALSE` = 0L)
    if (!"TRUE"  %in% colnames(tab)) tab <- cbind(tab,  `TRUE`  = 0L)
    tab <- tab[, c("FALSE", "TRUE")]
    ft  <- stats::fisher.test(tab, alternative = "two.sided")
    paste0("Wang-Allison pval: ", format.pval(ft$p.value, digits = 3, eps = 1e-4))
  }, error = function(e) "Wang-Allison pval: NA")

  if (is.null(band_plot)) {
    band_plot <- ggplot2::ggplot() + ggplot2::theme_classic() +
      ggplot2::annotate("text", x = xmin + 0.5 * xspan, y = band_y,
                        label = "no significant interval",
                        hjust = 0.5, vjust = 0.5, size = 3.8) +
      ggplot2::coord_cartesian(ylim = c(band_y - 0.3, band_y + 0.3),
                               clip = "off")
  }

  ## ---------- get correct strata names from km_plot$data ----------
  if (!"strata" %in% names(km_plot$data)) {
    stop("km_plot$data has no 'strata' column; cannot lock colors.")
  }
  strata_vals <- km_plot$data$strata
  strata_lev  <- levels(strata_vals)
  if (is.null(strata_lev)) strata_lev <- unique(strata_vals)

  ctrl_strata  <- grep(ctrl_name, strata_lev, value = TRUE)[1]
  if (is.na(ctrl_strata)) {
    stop("Could not find a strata level containing ctrl_name = ", ctrl_name)
  }

  treat_strata <- grep(treat_name, strata_lev, value = TRUE)[1]
  if (is.na(treat_strata)) {
    treat_strata <- setdiff(strata_lev, ctrl_strata)[1]
  }

  km_color_map <- setNames(c("black", "red"), c(ctrl_strata, treat_strata))
  ## -------------------------------------------------------------------------

  # --- KM pane ---
  km_core <- km_plot +
    ggplot2::labs(y = "Survival probability") +
    ggplot2::scale_color_manual(values = km_color_map, breaks = names(km_color_map)) +
    ggplot2::scale_fill_manual(values  = km_color_map, breaks = names(km_color_map)) +
    ggplot2::scale_x_continuous(limits = c(xmin, xmax),
                                expand = ggplot2::expansion(mult = 0)) +
    ggplot2::theme_classic() +
    ggplot2::theme(
      axis.title.x = ggplot2::element_blank(),
      axis.text.x  = ggplot2::element_blank(),
      axis.ticks.x = ggplot2::element_blank(),
      plot.margin  = grid::unit(c(pad_km[1], pad_km[2], pad_km[3], 2), "pt"),
      axis.title.y = ggplot2::element_text(margin = ggplot2::margin(r = 0)),
      axis.text.y  = ggplot2::element_text(margin = ggplot2::margin(r = 0))
    ) +
    ggplot2::annotate("text", x = p_x, y = p_y_top,
                      label = pval_lab, hjust = 0, vjust = 0, size = 5) +
    ggplot2::annotate("text", x = p_x, y = p_y_wa,
                      label = wa_label, hjust = 0, vjust = 0, size = 5)

  # --- Band pane ---
  band_core <- band_plot +
    ggplot2::labs(title = NULL, y = NULL, x = xlab) +
    ggplot2::theme(plot.title  = ggplot2::element_blank(),
                   axis.title.y = ggplot2::element_blank()) +
    ggplot2::scale_x_continuous(limits = c(xmin, xmax),
                                expand = ggplot2::expansion(mult = 0)) +
    ggplot2::scale_y_continuous(limits = c(band_y - 0.3, band_y + 0.3),
                                expand = ggplot2::expansion(mult = 0)) +
    ggplot2::annotate("text", x = xmin + 0.01 * xspan, y = band_y,
                      label = treat_name, hjust = 0, vjust = 0.5,
                      size = 3.8, color = "black") +
    ggplot2::coord_cartesian(clip = "off") +
    ggplot2::theme_classic() +
    ggplot2::theme(
      legend.position = "none",
      axis.text.y  = ggplot2::element_blank(),
      axis.ticks.y = ggplot2::element_blank(),
      plot.margin  = grid::unit(pad_bn, "pt")
    )

  (km_core / band_core) + patchwork::plot_layout(heights = heights)
}
