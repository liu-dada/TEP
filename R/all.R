#' Run Full TEP Analysis Workflow
#'
#' This function runs the entire analysis workflow for survival data:
#' Kaplan–Meier curves, hazard estimation (asymptotic and bootstrap),
#' HR plots, hazard plots, and confidence band plots.
#'
#' @param data Data frame containing at least `age`, `dead`, and `group`.
#' @param var Character. Name of the variable for hazard estimation.
#' @param contr Character. Name of the control group.
#' @param lim0 Numeric. Lower limit for plots (default 0).
#' @param lim1 Numeric. Upper limit for plots (default 1500).
#'
#' @return A named list containing:
#' \itemize{
#'   \item \code{Asymptotic} - hazard estimates (asymptotic)
#'   \item \code{bootstrap} - hazard estimates (bootstrap)
#'   \item \code{kmplot} - Kaplan–Meier plot object
#'   \item \code{hrplot_asymptotic} - hazard ratio plot (asymptotic)
#'   \item \code{hrplot_bootstrap} - hazard ratio plot (bootstrap)
#'   \item \code{hazardplot} - combined hazard plot
#'   \item \code{bandplot1} - confidence band plot (asymptotic)
#'   \item \code{bandplot2} - confidence band plot (bootstrap)
#'   \item \code{km_band_asymptotic} - KM curve with asymptotic bands
#'   \item \code{km_band_bootstrap} - KM curve with bootstrap bands
#' }
#'
#' @importFrom survival Surv survfit
#' @importFrom survminer ggsurvplot
#' @export
all_func <- function(data, var, contr, lim0 = 0, lim1 = 1500) {

  # Reset augmentation state before running
  reset_aug_state()

  # ---- 1. Kaplan–Meier curve ----
  fit <- survfit(Surv(age, dead) ~ group, data = data)
  km <- survminer::ggsurvplot(fit, data = data, pval = FALSE, palette = c('black', 'red'))

  # ---- 2. Asymptotic hazard estimation ----
  d1 <- hazardSE(data, contr, var)
  p1 <- hrplot(d1, var, lim0 = lim0, lim1 = lim1)

  # ---- 3. Bootstrap hazard estimation ----
  set.seed(42)  # reproducible augmentation/bootstrap
  d2 <- bshr(data, contr, var)
  p2 <- hrplot(d2, var, lim0 = lim0, lim1 = lim1)

  # ---- 4. Hazard plot ----
  hp <- hplot(d1, contr, var)

  # ---- 5. Confidence band plots ----
  pb  <- band_func(data1 = data, data2 = d1, lim0 = lim0, lim1 = lim1, var = var)
  pb2 <- band_func(data1 = data, data2 = d2, lim0 = lim0, lim1 = lim1, var = var)

  # ---- 6. KM curves with bands ----
  km_band_asymptotic <- make_km_band(
    km_plot    = km$plot,
    band_plot  = pb,
    data       = data,
    ctrl_name  = contr,
    treat_name = "TEP"
  )

  km_band_bootstrap <- make_km_band(
    km_plot    = km$plot,
    band_plot  = pb2,
    data       = data,
    ctrl_name  = contr,
    treat_name = "TEP"
  )

  # ---- 7. Return results as a list ----
  return(list(
    Asymptotic         = d1,
    bootstrap          = d2,
    kmplot             = km,
    hrplot_asymptotic  = p1,
    hrplot_bootstrap   = p2,
    hazardplot         = hp,
    bandplot1          = pb,
    bandplot2          = pb2,
    km_band_asymptotic = km_band_asymptotic,
    km_band_bootstrap  = km_band_bootstrap
  ))
}
