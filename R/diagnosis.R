#' Diagnose augmentation usage and generate diagnostics
#'
#' Reports whether jittered data augmentation was used in
#' \code{safe_bshazard()} and optionally generates diagnostic plots.
#'
#' @param data Original dataset used for modeling
#' @param out_dir Optional directory to save diagnostic plots
#' @param reps Number of replications for augmentation
#'
#' @return Invisibly returns a character vector of messages
#' @importFrom survival Surv survfit
#' @importFrom ggplot2 ggsave
#' @export
diagnose_augmentation <- function(data, out_dir = NULL, reps = 10) {

  .msg <- character(0)

  # ---- Report augmentation ----
  msg_reason <- if (!isTRUE(TEP_AUG_STATE$used_aug)) {
    "No singular-system error encountered."
  } else {
    paste0("bshazard error: ", TEP_AUG_STATE$reason)
  }

  .msg <- c(
    .msg,
    paste0(
      "Data augmentation required: ",
      if (isTRUE(TEP_AUG_STATE$used_aug)) "YES" else "NO"
    ),
    paste0("Reason: ", msg_reason)
  )

  # ---- Run diagnostics only if needed ----
  if (isTRUE(TEP_AUG_STATE$used_aug) && !is.null(out_dir)) {

    set.seed(42)
    t_aug <- augment_surv_data(data, reps = reps)

    fit_orig <- survival::survfit(survival::Surv(age, dead) ~ group, data = data)
    fit_aug  <- survival::survfit(survival::Surv(age, dead) ~ group, data = t_aug)

    p1 <- survminer::ggsurvplot(fit_orig, data = data)$plot
    p2 <- survminer::ggsurvplot(fit_aug, data = t_aug)$plot

    combined <- p1 + p2

    ggplot2::ggsave(
      filename = file.path(out_dir, "km_comparison.png"),
      plot = combined
    )

    .msg <- c(.msg, paste0("Saved diagnostic plot to: ", out_dir))
  }

  for (m in .msg) message(m)

  invisible(.msg)
}
