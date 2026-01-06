#' Hazard Ratio Plot
#'
#' Creates a line plot of hazard ratio (HR) over time, including pointwise
#' estimates and confidence intervals.
#'
#' @param data A `data.frame` containing hazard ratio results. Must include columns:
#'   - `time`: time points
#'   - `loghr`: log hazard ratio
#'   - `low`: lower bound of log hazard ratio
#'   - `up`: upper bound of log hazard ratio
#' @param var Character. Name of the treatment group (used for plot title).
#' @param lim0 Numeric. Minimum x-axis limit (default 0).
#' @param lim1 Numeric. Maximum x-axis limit (default 1500).
#'
#' @return A `ggplot` object showing the hazard ratio over time, with solid line for
#'   log(HR) and dashed lines for confidence intervals.
#'
#' @details
#' The function reshapes the input `data` from wide to long format using `tidyr::gather()`,
#' then creates a line plot using `ggplot2`, with separate line types for log(HR)
#' and its confidence bounds. A horizontal dashed line is added at 0 for reference.
#'
#' @export
#' @importFrom ggplot2 ggplot aes geom_line xlab ylab ggtitle theme_classic
#'   scale_linetype_manual geom_hline xlim
#' @importFrom tidyr gather
#' @keywords hazard ratio plot
#'
#' @examples
#' \dontrun{
#' # Suppose bshr() has been used to create HR data
#' hr_data <- bshr(df, contr = "control", var = "treatment", n_boot = 100)
#' p <- hrplot(hr_data, var = "treatment", lim0 = 0, lim1 = 20)
#' print(p)
#' }



#hazard ratio plot
hrplot <- function(data,var,lim0=0,lim1=1500){
  temp <- data[,c('time','loghr','low','up')]
  #wide to long
  t <- gather(temp, stats, value, 2:4, factor_key=TRUE)

  p <- ggplot(t,aes(x=time,y=value))+
    geom_line(aes(linetype=stats))+
    xlab("Age (Days)")+
    ylab('Hazard Ratio')+
    ggtitle(var)+
    theme_classic(base_size = 20)+
    scale_linetype_manual(values=c('solid','dashed','dashed'))+
    geom_hline(yintercept=0, linetype="dashed",
               color = "black", size=1)+
    xlim(lim0,lim1)

  return(p)

}
