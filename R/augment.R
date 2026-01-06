#' Augment survival data by jittering event times
#'
#' This function performs simple data augmentation for survival analysis by
#' replicating each subject's record multiple times and adding small Gaussian
#' noise (jitter) to the event time variable. The jitter scale is chosen
#' automatically based on the spacing of observed event times, unless supplied
#' by the user.
#'
#' The event indicator and grouping variables are left unchanged. Jittered
#' event times are constrained to remain positive.
#'
#' @param df A data frame containing survival data. Must include at least the
#'   columns \code{age} (event or censoring time) and \code{dead} (event
#'   indicator, where 1 indicates an event and 0 indicates censoring).
#' @param reps Integer. Number of replicated copies to generate for each
#'   original observation.
#' @param age_sd Numeric. Standard deviation of the Gaussian noise added to
#'   \code{age}. If \code{NULL}, a default value is chosen based on the typical
#'   spacing of observed event times.
#'
#' @return A data frame with \code{nrow(df) * reps} rows, containing the
#'   augmented survival data.
#'
#' @details
#' When \code{age_sd} is not supplied, the jitter scale is set to 10\% of the
#' median spacing between distinct observed event times. If fewer than two
#' events are observed, a fallback value equal to 1\% of the maximum observed
#' age is used.
#'
#' @seealso \code{\link[bshazard]{bshazard}}
#'
#' @examples
#' \dontrun{
#' data <- data.frame(
#'   age = c(5, 8, 10),
#'   dead = c(1, 0, 1),
#'   group = c("A", "B", "A")
#' )
#'
#' aug <- augment_surv_data(data, reps = 5)
#' nrow(aug)
#' }
#'
#' @export


# Make multiple jittered copies of each subject's record
augment_surv_data <- function(df, reps = 10, age_sd = NULL) {
  # df must have columns: age, dead, group (and any others you like)

  # Choose a default jitter scale based on typical spacing of event times
  if (is.null(age_sd)) {
    uniq_ev <- sort(unique(df$age[df$dead == 1]))
    if (length(uniq_ev) >= 2) {
      age_sd <- 0.1 * stats::median(diff(uniq_ev))  # 10% of median spacing
    } else {
      age_sd <- 0.01 * max(df$age, na.rm = TRUE)    # fallback: 1% of max age
    }
  }

  # Replicate rows
  idx <- rep(seq_len(nrow(df)), each = reps)
  out <- df[idx, , drop = FALSE]

  # Add Gaussian noise to ages (x_i), leave dead and group untouched
  out$age <- out$age + stats::rnorm(nrow(out), mean = 0, sd = age_sd)

  # Avoid non-positive ages
  min_pos <- min(df$age[df$age > 0], na.rm = TRUE)
  out$age[out$age <= 0] <- min_pos

  out
}


