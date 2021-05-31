NEONDataDownload = function(Sites,forecast_date){

# Download and save NEON data

  # install.packages("devtools")
  # install.packages("neonUtilities")
  # install.packages("raster")
  # devtools::install_github("NEONScience/NEON-geolocation/geoNEON")
  
  # load packages
  library(neonUtilities)
  library(geoNEON)
  library(raster)
  
  # Set global option to NOT convert all character variables to factors
  options(stringsAsFactors=F)
  
  # Download net radiation data
  
  net_rad <- loadByProduct(dpID="DP1.00023.001",
                           site=Sites,
                           package="expanded",
                           check.size=F,
                           nCores = 4,
                           timeIndex = 30)
  
    list2env(net_rad, .GlobalEnv)
  
    write.csv(SLRNR_30min, 
              paste0("NEONData/",forecast_date,"/SLRNR_30min.csv"), 
              row.names=F)
    write.csv(variables_00023, 
              paste0("NEONData/",forecast_date,"/variables_00023.csv"), 
              row.names=F)
  
    rm(list=ls())
  
  # Download air temp data
  air_tmp <- loadByProduct(dpID="DP1.00002.001",
                           site=Sites,
                           package="expanded",
                           check.size=F,
                           nCores = 4,
                           timeIndex = 30)
  
    list2env(air_tmp, .GlobalEnv)
    
    write.csv(SAAT_30min, 
              paste0("NEONData/",forecast_date,"/SAAT_30min.csv"), 
              row.names=F)
    write.csv(variables_00002, 
              paste0("NEONData/",forecast_date,"/variables_00002.csv"), 
              row.names=F)
    
    rm(list=ls())
  
  # Download wind speed data
  wnd_spd <- loadByProduct(dpID="DP1.00001.001", 
                           site=Sites,
                           package="expanded",
                           check.size=F, 
                           nCores = 4, 
                           timeIndex = 30)
  
    list2env(wnd_spd, .GlobalEnv)
    
    write.csv(`2DWSD_30min`, 
              paste0("NEONData/",forecast_date,"/2DWSD_30min.csv"), 
              row.names=F)
    write.csv(variables_00001, 
              paste0("NEONData/",forecast_date,"/variables_00001.csv"), 
              row.names=F)
    
    rm(list=ls())
  
  # Download precip data
  tot_ppt <- loadByProduct(dpID="DP1.00006.001", 
                           site=Sites,
                           package="expanded", 
                           check.size=F,
                           nCores = 4, 
                           timeIndex = 30)
  
    list2env(tot_ppt, .GlobalEnv)
    
    write.csv(THRPRE_30min, 
              paste0("NEONData/",forecast_date,"/THRPRE_30min.csv"), 
              row.names=F)
    write.csv(variables_00006, 
              paste0("NEONData/",forecast_date,"/variables_00006.csv"), 
              row.names=F)
    
    rm(list=ls())
  
  # Download pressure data
  sur_pre <- loadByProduct(dpID="DP1.00004.001", 
                           site=Sites,
                           package="expanded", 
                           check.size=F, 
                           nCores = 4,
                           timeIndex = 30)
  
    list2env(sur_pre, .GlobalEnv)
    
    write.csv(BP_30min, 
              paste0("NEONData/",forecast_date,"/BP_30min.csv"), 
              row.names=F)
    write.csv(variables_00004, 
              paste0("NEONData/",forecast_date,"/variables_00004.csv"), 
              row.names=F)
    
    rm(list=ls())
  
  # Download relative humidity data
  rel_hum <- loadByProduct(dpID="DP1.00098.001", 
                           site=Sites,
                           package="expanded", 
                           check.size=F, 
                           nCores = 4, 
                           timeIndex = 30)
  
    list2env(rel_hum, .GlobalEnv)
    
    write.csv(RH_30min, 
              paste0("NEONData/",forecast_date,"/RH_30min.csv"), 
              row.names=F)
    write.csv(variables_00098, 
              paste0("NEONData/",forecast_date,"/variables_00098.csv"), 
              row.names=F)
    
    rm(list=ls())
}