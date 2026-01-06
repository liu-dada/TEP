utils::globalVariables(c(
  "age", "dead", "group",
  "median", "lower", "upper"
))
#' Utility Helpers for Time, Percent Change, and KM Summaries
#'
#' These small helper functions provide convenience utilities for:
#'
#' - converting time from days to months,
#' - computing percent change between two values,
#' - summarizing Kaplan–Meier survival results by group (median survival and maximum observed event time).
#'
#' They are used internally for reporting and plotting survival-based summaries.
#'
#' @param x Numeric vector of time values in days.
#' @param tv Numeric. Treatment value.
#' @param cv Numeric. Control value.
#' @param df A data frame containing at least `age`, `dead`, and `group`.
#'
#' @details
#' `km_summaries_days()` fits a Kaplan–Meier model by group and returns:
#' - median survival time with confidence limits (in days),
#' - maximum observed event time (among subjects with events).
#'
#' @return
#' - `days_to_months()` returns a numeric vector in months.
#' - `pct_change()` returns a numeric percent change.
#' - `km_summaries_days()` returns a data frame with one row per group.
#'
#' @importFrom survival Surv survfit
#' @importFrom survminer surv_median
#' @importFrom dplyr filter group_by summarise select left_join
#' @importFrom magrittr %>%
#'
#' @examples
#' days_to_months(365)
#'
#' pct_change(tv = 120, cv = 100)
#'
#' \dontrun{
#' set.seed(123)
#' dat <- data.frame(
#'   age   = runif(200, 1, 1500),
#'   dead  = rbinom(200, 1, 0.4),
#'   group = sample(c("Control", "Treatment"), 200, replace = TRUE)
#' )
#'
#' km_summaries_days(dat)
#' }
#'
#' @name tep_utils

NULL

#' @rdname tep_utils
#' @export
days_to_months <- function(x) x / 30.44

#' @rdname tep_utils
#' @export
pct_change     <- function(tv, cv) 100 * (tv - cv) / cv

#' @rdname tep_utils
#' @export
km_summaries_days <- function(df) {
  fit <- survfit(Surv(age, dead) ~ group, data = df)
  med <- surv_median(fit)
  med$strata <- gsub("^group=", "", med$strata)
  names(med)[names(med) == "strata"] <- "group"
  maxd <- df %>% filter(dead == 1) %>% group_by(group) %>%
    summarise(max_age_days = max(age, na.rm = TRUE), .groups = "drop")
  dplyr::left_join(
    med %>% dplyr::select(group, median_days = median, lower_days = lower, upper_days = upper),
    maxd, by = "group"
  )
}
