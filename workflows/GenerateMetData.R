# This function is a hot, hot mess. Messier than my bedroom. Messier than my
# Fresher's Week. Just... don't judge me. 

GenerateMetData <- function(Site){

  # Function to generate a met file .csv from downloaded NEON data, which is 
  # assumed to be generated using the NEONDataDownload.R script.
  
  message("----------------------------------------------------\n%%%%%%%%%%% Generating Met File for ",
          Site,
          " %%%%%%%%%%%\n----------------------------------------------------")
  # Load libraries
  library(neonUtilities)
  library(geoNEON)
  library(raster)
  library(tidyverse)
  library(zoo)
  
  #%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  # NET RADIATION
  #%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  #
  hour = c("00",
           "01",
           "02",
           "03",
           "04",
           "05",
           "06",
           "07",
           "08",
           "09",
           "10",
           "11",
           "12",
           "13",
           "14",
           "15",
           "16",
           "17",
           "18",
           "19",
           "20",
           "21",
           "22",
           "23")
  
  message("Formatting radiation data")
  # Load radiation data
  rad30 <- readTableNEON(
    dataFile="./NEONData/SLRNR_30min.csv",
    varFile="./NEONData/variables_00023.csv")
  
  # Extract the relevant info 
  net_rad = rad30[rad30$siteID==Site,c("startDateTime","siteID","inSWMean","inLWMean")]
  
  # Add hours and minutes to dates
  net_rad$hour = rep(hour,each = 2)
  net_rad$minute = rep(c("00","30"))
  net_rad$time = paste0(net_rad$startDateTime," ",net_rad$hour,":",net_rad$minute)
  
  # Re-time to half-hourly in case multiple measurements exist
  net_rad_hh <- net_rad %>%
    group_by(time) %>%               
    summarise(inSWMean = mean(inSWMean,na.rm=TRUE),
              inLWMean = mean(inLWMean,na.rm=TRUE))
  
  # Extract just the hour
  net_rad_hh$time = substr(net_rad_hh$time,1,13)
  # Re-time to hourly
  net_rad_hourly <- net_rad_hh %>%
    group_by(time) %>% 
    summarise(inSWMean = mean(inSWMean,na.rm=TRUE),
              inLWMean = mean(inLWMean,na.rm=TRUE))
  
  # Clean up
  rm(list=c("rad30","net_rad","net_rad_hh"))
  
  #%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  # AIR TEMPERATURE
  #%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  message("Formatting temperature data")
  # Load temperature data
  tas30 <- readTableNEON(
    dataFile="./NEONData/SAAT_30min.csv",
    varFile="./NEONData/variables_00002.csv")
  
  # Extract the relevant info 
  air_tmp = tas30[tas30$siteID==Site,c("startDateTime","tempSingleMean")]
  
  # Add hours and minutes to dates
  air_tmp$hour = rep(hour, each = 2)
  air_tmp$minute = rep(c("00","30"))
  air_tmp$time = paste0(air_tmp$startDateTime," ",air_tmp$hour,":",air_tmp$minute)
  
  # Re-time to half-hourly in case multiple measurements exist
  air_tmp_hh <- air_tmp %>%
    group_by(time) %>%               
    summarise(tempSingleMean = mean(tempSingleMean,na.rm=TRUE))
  
  # Extract just the hour
  air_tmp_hh$time = substr(air_tmp_hh$time,1,13)
  # Re-time to hourly
  air_tmp_hourly <- air_tmp_hh %>%
    group_by(time) %>% 
    summarise(tempSingleMean = mean(tempSingleMean,na.rm=TRUE))
  
  # Clean up
  rm(list=c("tas30","air_tmp","air_tmp_hh"))
  
  #%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  # WIND SPEED
  #%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  message("Formatting wind speed data")
  # Load wind speed data
  wnd30 <- readTableNEON(
    dataFile="./NEONData/2DWSD_30min.csv",
    varFile="./NEONData/variables_00001.csv")
  
  # Extract the relevant info 
  wnd_spd = wnd30[wnd30$siteID==Site,c("startDateTime","windSpeedMean")]
  
  # Add hours and minutes to dates
  wnd_spd$hour = rep(hour, each = 2)
  wnd_spd$minute = rep(c("00","30"))
  wnd_spd$time = paste0(wnd_spd$startDateTime," ",wnd_spd$hour,":",wnd_spd$minute)
  
  # Re-time to half-hourly in case multiple measurements exist
  wnd_spd_hh <- wnd_spd %>%
    group_by(time) %>%               
    summarise(windSpeedMean = mean(windSpeedMean,na.rm=TRUE))
  
  # Extract just the hour
  wnd_spd_hh$time = substr(wnd_spd_hh$time,1,13)
  # Re-time to hourly
  wnd_spd_hourly <- wnd_spd_hh %>%
    group_by(time) %>% 
    summarise(windSpeedMean = mean(windSpeedMean,na.rm=TRUE))
  
  # Clean up
  rm(list=c("wnd30","wnd_spd","wnd_spd_hh"))
  
  #%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  # PRECIPITATION
  #%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  message("Formatting precipitation data")
  # Load precip data
  ppt30 <- readTableNEON(
    dataFile="./NEONData/THRPRE_30min.csv",
    varFile="./NEONData/variables_00006.csv")
  
  # Extract the relevant info 
  tot_ppt = ppt30[ppt30$siteID==Site,c("startDateTime","TFPrecipBulk")]
  
  # Add hours and minutes to dates
  tot_ppt$hour = rep(hour, each = 2)
  tot_ppt$minute = rep(c("00","30"))
  tot_ppt$time = paste0(tot_ppt$startDateTime," ",tot_ppt$hour,":",tot_ppt$minute)
  
  # Re-time to half-hourly in case multiple measurements exist
  tot_ppt_hh <- tot_ppt %>%
    group_by(time) %>%               
    summarise(TFPrecipBulk = sum(TFPrecipBulk,na.rm=TRUE))
  
  # Extract just the hour
  tot_ppt_hh$time = substr(tot_ppt_hh$time,1,13)
  # Re-time to hourly
  tot_ppt_hourly <- tot_ppt_hh %>%
    group_by(time) %>% 
    summarise(TFPrecipBulk = sum(TFPrecipBulk,na.rm=TRUE))
  
  # Clean up
  rm(list=c("ppt30","tot_ppt","tot_ppt_hh"))
  
  #%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  # SURFACE PRESSURE
  #%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  message("Formatting surface pressure data")
  # Load pressure data
  pre30 <- readTableNEON(
    dataFile="./NEONData/BP_30min.csv",
    varFile="./NEONData/variables_00004.csv")
  
  # Extract the relevant info 
  sur_pre = pre30[pre30$siteID==Site,c("startDateTime","staPresMean")]
  
  # Add hours and minutes to dates
  sur_pre$hour = rep(hour, each = 2)
  sur_pre$minute = rep(c("00","30"))
  sur_pre$time = paste0(sur_pre$startDateTime," ",sur_pre$hour,":",sur_pre$minute)
  
  # Re-time to half-hourly in case multiple measurements exist
  sur_pre_hh <- sur_pre %>%
    group_by(time) %>%               
    summarise(staPresMean = mean(staPresMean,na.rm=TRUE))
  
  # Extract just the hour
  sur_pre_hh$time = substr(sur_pre_hh$time,1,13)
  # Re-time to hourly
  sur_pre_hourly <- sur_pre_hh %>%
    group_by(time) %>% 
    summarise(staPresMean = mean(staPresMean,na.rm=TRUE))
  
  # Clean up
  rm(list=c("pre30","sur_pre","sur_pre_hh"))
  
  #%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  # RELATIVE HUMIDITY
  #%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  message("Formatting humidity data")
  # Load relative humidity data
  rh30 <- readTableNEON(
    dataFile="./NEONData/RH_30min.csv",
    varFile="./NEONData/variables_00098.csv")
  
  # Extract the relevant info 
  rel_hum = rh30[rh30$siteID==Site,c("startDateTime","RHMean")]
  
  # Add hours and minutes to dates
  rel_hum$hour = rep(hour, each = 2)
  rel_hum$minute = rep(c("00","30"))
  rel_hum$time = paste0(rel_hum$startDateTime," ",rel_hum$hour,":",rel_hum$minute)
  
  # Re-time to half-hourly in case multiple measurements exist
  rel_hum_hh <- rel_hum %>%
    group_by(time) %>%               
    summarise(RHMean = mean(RHMean,na.rm=TRUE))

  # Extract just the hour
  rel_hum_hh$time = substr(rel_hum_hh$time,1,13)
  # Re-time to hourly
  rel_hum_hourly <- rel_hum_hh %>%
    group_by(time) %>% 
    summarise(RHMean = mean(RHMean,na.rm=TRUE))
  
  # Clean up
  rm(list=c("rh30","rel_hum","rel_hum_hh"))
  
  #%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  # Output
  #%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  message("Saving met file")
  # Merge the different data
  climate = merge(air_tmp_hourly,net_rad_hourly,by.x = "time",by.y="time", all = TRUE)
  climate = merge(climate,rel_hum_hourly,by.x = "time",by.y="time", all = TRUE)
  climate = merge(climate,sur_pre_hourly,by.x = "time",by.y="time", all = TRUE)
  climate = merge(climate,tot_ppt_hourly,by.x = "time",by.y="time", all = TRUE)
  climate = merge(climate,wnd_spd_hourly,by.x = "time",by.y="time", all = TRUE)
  
  climate$time = as.POSIXct(climate$time,format = "%Y-%m-%d %H",tz="UTC")
  
  # Interpolate over the NA values
  climate[,2:8] = lapply(climate[,2:8], function(x) na.approx(x,na.rm=FALSE))
  
  # Remove any rows at the start that have NA values
  message("Removing NA values from start of record")
  k = 0
  while (any(is.na(climate[1,]))==TRUE){
    climate = climate[-1,]
    k = k+1
  }
  message(k," rows with NA data removed")
  
  finaldate = as.Date(tail(climate$time,1))
  write.table(climate,
              paste0("data/NEON/raw/NEONMetFile_",Site,"_",finaldate,".csv"),
              sep = ",",
              dec=".",
              row.names = FALSE)
}
