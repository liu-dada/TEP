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
#' @return A fitted bshazard model object. The returned object includes
#'   additional attributes:
#'   \itemize{
#'     \item \code{used_aug}: logical indicating whether data augmentation was used
#'     \item \code{aug_reason}: character string describing the error that triggered augmentation (if used)
#'   }
#' @details
#' If the initial model fit fails due to a computationally singular system,
#' the function retries using jittered data augmentation via
#' \code{augment_surv_data()}.
#'
#' The function also records whether augmentation was used. This information
#' is stored both as attributes in the returned model object and in a
#' package-level environment. Use \code{reset_aug_state()} to reset the
#' global tracking state.
#' @export

# Wrap bshazard with automatic fallback to jittered-augmented data

safe_bshazard <- function(formula, data, ..., reps = 10, age_sd = NULL) {
  tryCatch(
    {
      fit <- bshazard::bshazard(formula, data = data, ...)
      attr(fit, "used_aug") <- FALSE
      fit
    },
    error = function(e) {
      msg <- conditionMessage(e)
      if (grepl("computationally singular", msg)) {
        # record that augmentation was needed somewhere in this run
        TEP_AUG_STATE$used_aug <- TRUE


        if (is.na(TEP_AUG_STATE$reason)) {
          TEP_AUG_STATE$reason <- msg
        }

        message("bshazard failed (singular system). Retrying with jittered data augmentation...")
        data_aug <- augment_surv_data(data, reps = reps, age_sd = age_sd)

        fit2 <- bshazard::bshazard(formula, data = data_aug, ...)
        attr(fit2, "used_aug") <- TRUE
        attr(fit2, "aug_reason") <- msg
        fit2
      } else {
        stop(e)
      }
    }
  )
}
