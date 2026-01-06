
#' Hazard Rate Plot
#'
#' Creates a line plot of mortality hazard over time for a treatment and control group.
#'
#' @param data A `data.frame` containing hazard rate results. Must include columns:
#'   - `time`: time points
#'   - `h0`: hazard rate for control group
#'   - `h1`: hazard rate for treatment group
#'   - `name`: group name (optional, used internally)
#' @param contr Character. Name of the control group (used in legend).
#' @param var Character. Name of the treatment group (used for plot title).
#' @param lim0 Numeric. Minimum x-axis limit (default 0).
#' @param lim1 Numeric. Maximum x-axis limit (default 1500).
#'
#' @return A `ggplot` object showing hazard rates over time for both groups,
#'   with logarithmic y-axis scaling.
#'
#' @details
#' The function reshapes the input `data` from wide to long format using `tidyr::gather()`,
#' then creates a line plot using `ggplot2`, with separate colors for the control and
#' treatment groups. The y-axis is displayed on a log scale.
#'
#' @export
#' @importFrom ggplot2 ggplot aes geom_line xlab ylab ggtitle scale_y_log10
#'   theme_classic scale_color_manual labs xlim
#' @importFrom tidyr gather
#' @keywords hazard rate plot
#'
#' @examples
#' \dontrun{
#' # Suppose hazardSE() has been used to create hazard data
#' hr_data <- hazardSE(df, contr = "control", var = "treatment")
#' p <- hplot(hr_data, contr = "control", var = "treatment", lim0 = 0, lim1 = 20)
#' print(p)
#' }



#hazard rate plot
hplot <- function(data,contr,var,lim0=0,lim1=1500){
  temp <- data[,c('time','h0','h1','name')]
  #wide to long
  t <- gather(temp, stats, value, 2:3, factor_key=TRUE)

  p <- ggplot(t,aes(x=time,y=value))+
    geom_line(aes(color=stats))+
    xlab("Age (Days)")+
    ylab('Mortality Hazard')+
    ggtitle(var)+
    scale_y_log10()+
    theme_classic(base_size = 20)+
    scale_color_manual(values=c('black','red'),labels=c(contr,var))+
    labs(color = "Group")+
    xlim(lim0,lim1)

  return(p)

}
