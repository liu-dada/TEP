#' Example dataset with clear treatment effect
#'
#' Simulated survival data where the treatment group has a higher hazard
#' than the control group, resulting in a clear separation in survival curves
#' and significant statistical results.
#'
#' @format A data frame with 200 rows and 3 variables:
#' \describe{
#'   \item{age}{Survival time}
#'   \item{dead}{Event indicator (1 = death, 0 = censored)}
#'   \item{group}{Group label ("Control", "GTE")}
#' }
#'
#' @source Simulated data
"example_data_sig"
