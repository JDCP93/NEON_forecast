NEONSubmission <- function(forecast_date){
  
  # A function to take the CABLE outputs for a certain forecast date 
  # and return a single netCDF file, containing the individual ensemble 
  # forecasts for each site. 
  
  # Load the necessary libraries
  library(ncdf4)
  
  # Set the output filename
  outname = paste0("terrestrial-",forecast_date,"-norfolkcha.nc")
  
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
  
  data
  
}
