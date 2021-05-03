NEONSubmission <- function(forecast_date){
  
  # A function to take the CABLE outputs for a certain forecast date 
  # and return a dataframe of results as well as single netCDF file,
  # containing the mean ensemble forecasts for each site. 
  
  # Load the necessary libraries
  library(ncdf4)
  
  # Set the output filename
  outname = paste0("terrestrial_daily-",forecast_date,"-norfolkcha.nc")
  
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
  Data_day = Data_day[Data_day$time>=forecast_date,]
  
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

  # Create dataframe for netcdf export
  # statistic ID: 1 = mean, 2 = sd
  # site ID: 1 = BART, 2 = KONZ, 3 = OSBS, 4 = SRER
  CABLE.df = data.frame("time" = rep(SiteMean$time,6),
                        "site" = rep(SiteMean$site,6),
                        "statistic" = rep(1:2, each = nrow(SiteMean), times = 3),
                        "variable" = rep(c("nee","le","vswc"), each = 2*nrow(SiteMean)),
                        "value" = c(SiteMean$nee_mean,
                                    SiteMean$nee_sd,
                                    SiteMean$le_mean,
                                    SiteMean$le_sd,
                                    SiteMean$vswc_mean,
                                    SiteMean$vswc_sd))
  CABLE.df$site[CABLE.df$site=="BART"] = 1
  CABLE.df$site[CABLE.df$site=="KONZ"] = 2
  CABLE.df$site[CABLE.df$site=="OSBS"] = 3
  CABLE.df$site[CABLE.df$site=="SRER"] = 4
  
  # Define netcdf dimenions
  time_vals = time_length(interval(ymd(forecast_date), unique(SiteMean$time)), "second")
  siteID_vals = 1:4
  statistic_vals = 1:2
  #siteID_vals = c("BART","KONZ","OSBS","SRER")
  #statistic_vals = c("mean","sd")
  time = ncdim_def(name = "time",
                   units = paste0("seconds since ",forecast_date), 
                   vals = time_vals)
  siteID = ncdim_def(name = "siteID", 
                     units= "", 
                     longname = "NEON site ID index", 
                     vals = siteID_vals)
  statistic = ncdim_def(name = "statistic", 
                        units = "", 
                        longname = "statistic index", 
                        vals = statistic_vals)
  
  
  var_nee = ncvar_def(name = "nee", 
                      units = "umol/m^2/s", 
                      dim = list(time, siteID, statistic),
                      longname="Daily Net Ecosystem Exchange of CO2",
                      missval = -9999) 
  var_le = ncvar_def(name = "le", 
                     units = "W/m^2", 
                     dim = list(time, siteID, statistic),
                     longname="Daily Surface Latent Heat Flux",
                     missval = -9999) 
  var_vswc = ncvar_def(name = "vswc", 
                       units = "m^3/m^3", 
                       dim = list(time, siteID, statistic),
                       longname="Daily Volumetric Soil Water Content as a weighted average down to 2m",
                       missval = -9999) 
  
  ncnew = nc_create(outname,list(var_nee, var_le, var_vswc))
  
  print(paste("The file has",ncnew$nvars,"variables"))# 
  print(paste("The file has",ncnew$ndim,"dimensions"))# 
  
  ncvar_put( nc=ncnew, varid=var_nee, vals = CABLE.df$value[CABLE.df$variable=="nee"],start=c(1,1,1),count=c(36,4,2))
  
  output = list(data)
  
}
