#' Bootstrap Hazard Ratio Curve
#'
#' Computes a bootstrap estimate of the hazard ratio (HR) curve between a treatment
#' group and a control group over a common time grid. The function returns pointwise
#' log(HR) estimates and 95% bootstrap confidence intervals.
#'
#' @param data A `data.frame` containing survival data. Must include columns:
#'   - `age`: time of event or censoring
#'   - `dead`: event indicator (1 = event occurred, 0 = censored)
#'   - `group`: group identifier (factor or character)
#' @param contr Character. Name of the control group in `group`.
#' @param var Character. Name of the treatment group in `group`.
#' @param n_boot Integer. Number of bootstrap resamples (default 1000).
#' @param step Numeric. Spacing of the common time grid (default 1).
#' @param eps Numeric. Small offset to avoid `log(0)` (default 1e-9).
#'
#' @return A `data.frame` with columns:
#'   - `time`: grid of time points
#'   - `loghr`: pointwise mean of log hazard ratio across bootstrap samples
#'   - `low`: lower 95% confidence bound of log HR
#'   - `up`: upper 95% confidence bound of log HR
#'   - `name`: treatment group name
#'
#' @details
#' The function first constructs a global time grid based on the overlap of event times
#' between treatment and control groups. Then, it performs bootstrap resampling of
#' subjects to compute hazard estimates via `safe_bshazard()` and calculates log(HR)
#' for each bootstrap sample on the same time grid. Finally, it summarizes the results
#' by computing pointwise mean and 95% bootstrap confidence intervals.
#'
#' @export
#' @importFrom stats approx
#' @importFrom stats quantile
#' @keywords survival hazard ratio bootstrap
#'
#' @examples
#' \dontrun{
#' df <- data.frame(
#'   age = c(5, 10, 7, 12),
#'   dead = c(1, 0, 1, 0),
#'   group = c("control", "control", "treatment", "treatment")
#' )
#' boot_hr <- bshr(df, contr = "control", var = "treatment", n_boot = 100)
#' head(boot_hr)
#' }




#==========================================================
# Bootstrap hazard–ratio curve on a common time grid
#   data  : data.frame with columns age, dead, group
#   contr : name of control group (character)
#   var   : name of treatment group (character)
#==========================================================
bshr <- function(data, contr, var,
                 n_boot    = 1000,
                 step      = 1,      # spacing of time grid (days)
                 eps       = 1e-9) { # tiny offset to avoid log(0)

  # keep only the two groups of interest
  temp <- subset(data, group %in% c(var, contr))

  #--------------------------------------------------------
  # 1) Build a GLOBAL time grid, common to all bootstraps
  #    Use the overlap of the two groups' event-time ranges
  #--------------------------------------------------------
  base0 <- safe_bshazard(Surv(age, dead) ~ 1,
                         data = subset(temp, group == contr))
  base1 <- safe_bshazard(Surv(age, dead) ~ 1,
                         data = subset(temp, group == var))

  min_common <- max(min(base0$time[base0$hazard > 0], na.rm = TRUE),
                    min(base1$time[base1$hazard > 0], na.rm = TRUE))
  max_common <- min(max(base0$time[base0$hazard > 0], na.rm = TRUE),
                    max(base1$time[base1$hazard > 0], na.rm = TRUE))

  global_times <- seq(from = min_common, to = max_common, by = step)

  #--------------------------------------------------------
  # 2) Bootstrap: for each resample, compute log(HR(t))
  #    on the SAME global_times grid
  #--------------------------------------------------------
  # pre-allocate list to store one vector of logHR per bootstrap
  loghr_list <- vector("list", length = n_boot)

  for (b in seq_len(n_boot)) {
    # resample subjects with replacement
    bt <- temp[sample(seq_len(nrow(temp)), nrow(temp), replace = TRUE), ]

    fit0 <- safe_bshazard(Surv(age, dead) ~ 1,
                          data = subset(bt, group == contr))
    fit1 <- safe_bshazard(Surv(age, dead) ~ 1,
                          data = subset(bt, group == var))

    bh0 <- data.frame(time = fit0$time, hazard = fit0$hazard)
    bh1 <- data.frame(time = fit1$time, hazard = fit1$hazard)

    # interpolate both hazards on the COMMON grid
    # rule = 2: use boundary values outside range (avoids extra NAs)
    fi0 <- approx(x = bh0$time, y = bh0$hazard,
                  xout = global_times, rule = 2)
    fi1 <- approx(x = bh1$time, y = bh1$hazard,
                  xout = global_times, rule = 2)

    h0 <- pmax(fi0$y, eps)  # avoid 0
    h1 <- pmax(fi1$y, eps)

    loghr_list[[b]] <- log(h1 / h0)
  }

  #--------------------------------------------------------
  # 3) Combine bootstraps into a matrix and summarise
  #--------------------------------------------------------
  loghr_mat <- do.call(cbind, loghr_list)  # rows: time, cols: bootstrap

  # drop rows where everything is NA (should be rare with rule = 2)
  keep <- apply(!is.na(loghr_mat), 1, any)
  loghr_mat <- loghr_mat[keep, , drop = FALSE]
  time_vec  <- global_times[keep]

  final <- data.frame(
    time  = time_vec,
    loghr = apply(loghr_mat, 1, mean,     na.rm = TRUE),
    up    = apply(loghr_mat, 1, quantile, probs = 0.975, na.rm = TRUE),
    low   = apply(loghr_mat, 1, quantile, probs = 0.025, na.rm = TRUE)
  )

  final$name <- var
  return(final)
}
