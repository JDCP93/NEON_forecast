CheckNEONMet <- function(site,forecast_date){
  
  data = read.csv(paste0("data/NEON/processed/NEONMetFile_",site,"_",forecast_date,".csv"))
  
  library(lubridate)
  library(magrittr)
  library(tidyverse)
  
  # Create dataframe of daily values and QC counts
  data <- data[1:8760,] %>%
    mutate(time=as.Date(time, 
                        format="%Y-%m-%d")) %>%
    group_by(time) %>%               # group by the day column
    summarise("tair" = mean(tair),
               "rh" = mean(rh),
               "swdown" = mean(swdown),
               "wind" = mean(wind),
               "rainf" = sum(rainf)*60*60, # ppt in mm/s in hour blocks so turn into mm
               "vpd" = mean(vpd),
               "psurf" = mean(psurf),
               "lwdown" = mean(lwdown),
               "qair" = mean(qair))
  
  
  df = data.frame("time" = rep(data$time,11),
                    "variable" = rep(c("tair","rh","swdown","wind","rainf","vpd","psurf","lwdown","qair"),each = nrow(data)),
                    "value" = c(data$tair,data$rh,data$swdown,data$wind,data$rainf,data$vpd,data$psurf,data$lwdown,data$qair))
  
  
  library(ggplot2)
  plot <- ggplot(df) +
          geom_line(aes(x = time, y = value, group = variable)) +
          facet_wrap(~variable, scales = "free") +
          ggtitle(site)

}