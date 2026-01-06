#' Wang & Allison (2004) Helpers for Survival Percentile Analysis
#'
#' These functions implement the Wang & Allison (2004) approach for comparing survival
#' between two groups at a specified survival percentile:
#'
#' - `wa_percentile_age()` computes the age (time) corresponding to a given survival percentile.
#' - `wa_counts()` counts the number of individuals above and below the threshold in each group.
#' - `wang_allison_test()` performs the Fisher exact test at the threshold age for two groups.
#'
#' @param df A data frame containing at least columns `age`, `dead`, and `group`.
#' @param p Numeric between 0 and 1. The survival percentile (default 0.9 for the 90th percentile).
#' @param groups Optional character vector. Groups to include when calculating the percentile in `wa_percentile_age()`.
#' @param t_star Numeric. Threshold age corresponding to the percentile (output from `wa_percentile_age()`).
#' @param ctrl Character. Name of the control group.
#' @param treat Character. Name of the treatment group.
#' @param threshold_from Character. How to compute the threshold age in `wang_allison_test()`. Either `"pooled"` (default) or `"control"`.
#' @importFrom survival Surv
#' @importFrom stats fisher.test
#'
#' @return
#' - `wa_percentile_age()` returns a numeric value of the age at the specified percentile, or `NA_real_` if not computable.
#' - `wa_counts()` returns a 2x2 table of counts, rows are groups, columns are `FALSE` (below threshold) and `TRUE` (above threshold).
#' - `wang_allison_test()` returns a list with elements:
#'   - `t_star`: threshold age used,
#'   - `table`: the 2x2 counts table,
#'   - `fisher`: result of `fisher.test()` for the two groups.
#'
#' @examples
#' library(survival)
#' set.seed(123)
#' dat <- data.frame(
#'   age = runif(200, 1, 1500),
#'   dead = rbinom(200, 1, 0.4),
#'   group = sample(c("Control", "Treatment"), 200, replace = TRUE)
#' )
#'
#' # Compute 90th percentile age
#' t_star <- wa_percentile_age(dat, p = 0.9)
#'
#' # Count above/below threshold
#' wa_counts(dat, t_star, ctrl = "Control", treat = "Treatment")
#'
#' # Fisher exact test at 90th percentile
#' wang_allison_test(dat, ctrl = "Control", treat = "Treatment", p = 0.9)
#'
#' @name wang_allison_helpers
NULL

#' @rdname wang_allison_helpers
#' @export
wa_percentile_age <- function(df, p = 0.90, groups = NULL) {
  surv <- NULL  # trick R CMD check
  if (!is.null(groups)) df <- df[df$group %in% groups, , drop = FALSE]
  fit <- survfit(Surv(age, dead) ~ 1, data = df)
  sf <- data.frame(time = fit$time, surv = fit$surv)
  thr <- subset(sf, surv <= (1 - p))
  if (nrow(thr) == 0) return(NA_real_)
  thr$time[1]
}

#' @rdname wang_allison_helpers
#' @export
wa_counts <- function(df, t_star, ctrl, treat) {
  df2 <- df[df$group %in% c(ctrl, treat), c("group","age"), drop = FALSE]
  df2$to_threshold <- df2$age >= t_star  # TRUE/FALSE
  tab <- table(df2$group, df2$to_threshold)
  if (!"FALSE" %in% colnames(tab)) tab <- cbind(tab, `FALSE` = 0L)
  if (!"TRUE"  %in% colnames(tab)) tab <- cbind(tab,  `TRUE` = 0L)
  tab <- tab[, c("FALSE","TRUE")]
  tab[ c(ctrl, treat), , drop = FALSE ]
}

#' @rdname wang_allison_helpers
#' @export
wang_allison_test <- function(df, ctrl, treat, p = 0.90,
                              threshold_from = c("pooled","control")) {
  threshold_from <- match.arg(threshold_from)
  if (threshold_from == "pooled") {
    t_star <- wa_percentile_age(df[df$group %in% c(ctrl, treat), ], p = p)
  } else {
    t_star <- wa_percentile_age(df[df$group == ctrl, ], p = p)
  }
  if (!is.finite(t_star)) {
    return(list(t_star = NA_real_, table = NA, fisher = NA))
  }
  tab <- wa_counts(df, t_star, ctrl, treat)
  ft  <- fisher.test(tab, alternative = "two.sided")
  list(t_star = t_star, table = tab, fisher = ft)
}
