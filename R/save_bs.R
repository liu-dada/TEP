#' Safely fit a bshazard model
#'
#' This function wraps \code{bshazard::bshazard()} and automatically retries
#' with jittered data augmentation if a singular system error occurs.
#'
#' @importFrom survival Surv
#' @param formula A survival model formula
#' @param data A data frame containing survival data
#' @param ... Additional arguments passed to bshazard()
#' @param reps Number of replicated rows for data augmentation
#' @param age_sd Standard deviation for age jittering
#'
#' @return A fitted bshazard model object
#' @export

# Wrap bshazard with automatic fallback to jittered-augmented data
safe_bshazard <- function(formula, data, ..., reps = 10, age_sd = NULL) {
  # First try the vanilla bshazard
  tryCatch(
    {
      bshazard::bshazard(formula, data = data, ...)
    },
    error = function(e) {
      msg <- conditionMessage(e)
      if (grepl("computationally singular", msg)) {
        message("bshazard failed (singular system). ",
                "Retrying with jittered data augmentation...")
        data_aug <- augment_surv_data(data, reps = reps, age_sd = age_sd)
        bshazard::bshazard(formula, data = data_aug, ...)
      } else {
        stop(e)
      }
    }
  )
}
