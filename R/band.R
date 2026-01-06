if(getRversion() >= "2.15.1")  utils::globalVariables(
  c("time", "stats", "value", "group", "mean2")
)

#' Band Plot of Hazard Ratio Significance
#'
#' Creates a horizontal “band” plot highlighting periods where the hazard ratio is
#' statistically significant, along with median survival markers.
#'
#' @param data1 A `data.frame` with columns `age`, `dead`, and `group`, for survival data.
#' @param data2 A `data.frame` containing asymptotic or bootstrap hazard ratio results with columns:
#'   - `time`: time points
#'   - `loghr`: log hazard ratio
#'   - `low`: lower bound of confidence interval
#'   - `up`: upper bound of confidence interval
#'   - `name`: group name
#' @param lim0 Numeric. Minimum x-axis limit (default 0).
#' @param lim1 Numeric. Maximum x-axis limit (default 1500).
#' @param var Character. Name of the treatment group (used for selecting median and plot title).
#'
#' @return A `ggplot` object showing a horizontal band plot. Regions where the hazard
#'   ratio is significant (CI does not include zero) are highlighted in color. Median
#'   survival time is marked along the x-axis.
#'
#' @details
#' The function calculates median survival from `data1` using `survfit()` and
#' `surv_median()`. It highlights time intervals in `data2` where the log hazard ratio
#' is statistically significant. The x-axis is annotated with key time points including
#' the first and last significant times and the median survival time.
#'
#' @export
#' @importFrom survival survfit
#' @importFrom survminer surv_median
#' @importFrom ggplot2 ggplot aes geom_line scale_colour_gradient2 theme_classic
#'   scale_x_continuous ylab ggtitle theme element_text
#' @importFrom ggeasy easy_remove_axes
#' @keywords hazard ratio band plot
#'
#' @examples
#' \dontrun{
#' # Suppose you have survival data and bootstrap HR
#' p <- band_func(data1 = surv_data, data2 = bshr_data, lim0 = 0, lim1 = 1500, var = "treatment")
#' print(p)
#' }

#band
band_func <- function(data1,data2,lim0=0,lim1=1500,var){
  fit<- survfit(Surv(age, dead) ~ group, data = data1)
  #median
  m <- surv_median(fit)
  m$strata <- gsub('group=','',m$strata)

  #ci upper<0 or ci lower>0
  aw0 <- data2[!is.na(data2$loghr),]
  aw0$mean2 <- ifelse(aw0$up<0|aw0$low>0,aw0$loghr,0)


  if(length(unique(aw0$mean2))==1){p <- NULL}else{

    df <- aw0[,c('time','name','loghr','up','low','mean2')]

    #significant min and max
    firstf <- min(df$time[df$mean2!=0])
    lastf <- max(df$time[df$mean2!=0])

    #add median survival time
    mf <- m[m$strata==var,'median']


    #mark x axis
    br <- data.frame(bre=c(0,400,800,1200,1600,firstf,lastf,mf),
                     co=c(rep('black',5),rep('black',2),'purple'))
    br <- br[order(br$bre),]

    p <- ggplot(data=df, aes(x = time, y = 3, color = mean2)) +

      geom_line(size = 10)  +
      scale_colour_gradient2(midpoint = 0,high = "darkred", mid = 'white', low = "seagreen") +
      theme(legend.position="none")+

      theme_classic()+
      scale_x_continuous(breaks = br$bre,labels = br$bre,limits = c(lim0,lim1))+
      theme(axis.title.y=element_text(angle=0, vjust = 0.5),
            axis.text.x = element_text(colour = br$co))+
      ylab(var)+
      easy_remove_axes(which='y',what = c("ticks",  "text", "line"))+
      ggtitle(var)
  }
  return(p)
}
