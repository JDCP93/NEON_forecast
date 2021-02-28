NEONSubmission <- function(forecast_date){
  
  # A function to take the CABLE outputs for a certain forecast date 
  # and return a dataframe of results as well as single netCDF file,
  # containing the mean ensemble forecasts for each site. 
  
  # Load the necessary libraries
  library(ncdf4)
  library(magrittr)
  library(dplyr)
  library(tidyverse)
  
  # Set the output filename
  outname_csv = paste0("terrestrial_daily-",forecast_date,"-norfolkcha.csv")
  outname_R = paste0("terrestrial_daily-",forecast_date,"-norfolkcha.Rdata")
  
  # List the CABLE outputs for the forecast date
  files = list.files(paste0("outputs/",forecast_date,"/"),recursive = TRUE)
  
  # create empty dataframe
  data = data.frame()
  
  for (file in files){
    # Find the ensemble member and site that the output is for
    site = substr(file,1,4)
    ens = substr(file,25,26)

    # Open the netCDF file
    netcdf = nc_open(paste0("outputs/",forecast_date,"/",file))
    
    # Extract the time dimension required variables
    time = ncvar_get(netcdf,"time")
    time_from = substr(ncatt_get(netcdf, "time")$units, 15, 30)
    Hours_to_Secs = 3600
    time = as.POSIXct(time, origin=time_from, tz = "UTC")
    # Extract the required variables
    nee = ncvar_get(netcdf,"NEE")
    gpp = ncvar_get(netcdf,"GPP")
    le = ncvar_get(netcdf,"Qle")
    vswc = ncvar_get(netcdf,"SoilMoist")
    
    # Take weighted mean of the columns of vswc to integrate over ~2m
    vswc = (vswc[2,]*0.1 + vswc[3,]*0.2 + vswc[4,]*0.4 + vswc[5,]*1.1)/1.8
    
    # Place into a dataframe
    df = data.frame("time" = time,
                    "site" = rep(site,length(nee)),
                    "ensemble" = rep(ens,length(nee)),
                    "nee" = nee,
                    "gpp" = gpp,
                    "le" = le,
                    "vswc" = vswc)
    
    # Close the netCDF file
    nc_close(netcdf)
    
    data = rbind(data,df)
    
  }
  
  # Retime to daily
  Data_day <- data %>%
    mutate(time=as.Date(time, 
                        format="%Y-%m-%d")) %>%
    group_by(time,site,ensemble) %>%               # group by the day column
    summarise(nee = mean(nee),
              gpp = mean(gpp),
              le=mean(le),
              vswc=mean(vswc))
  
  # Cut to just the forecast period
  Data_day = Data_day[Data_day$time >= as.Date(forecast_date),]
  # Make sure we aren't overrunning the forecast
  Data_day = Data_day[Data_day$time < (as.Date(forecast_date)+days(34)),]
  
  # Group by site - i.e. ensemble means
  SiteMean = Data_day %>%
    group_by(time,site) %>%
    summarise(nee_mean = mean(nee),
              nee_sd = sd(nee,na.rm=TRUE),
              gpp_mean = mean(gpp),
              gpp_sd = sd(gpp,na.rm=TRUE),
              le_mean = mean(le),
              le_sd = sd(le),
              vswc_mean = mean(vswc),
              vswc_sd = sd(vswc))

  # Create df for csv export
  output.df = data.frame("time" = rep(SiteMean$time,2),
                         "statistic" = rep(c("mean","sd"), each = nrow(SiteMean)),
                        "siteID" = rep(SiteMean$site,2),
                        "nee" = c(SiteMean$nee_mean,SiteMean$nee_sd),
                        "le" = c(SiteMean$le_mean,SiteMean$le_sd),
                        "vswc" = c(SiteMean$vswc_mean,SiteMean$vswc_sd),
                        "forecast" = 1,
                        "data_assimilation" = 0)

  save(SiteMean,file = outname_R)
  write_csv(output.df,outname_csv)
  
}
