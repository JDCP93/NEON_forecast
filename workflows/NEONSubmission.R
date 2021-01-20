NEONSubmission <- function(forecast_date){
  
  # A function to take the CABLE outputs for a certain forecast date 
  # and return a single netCDF file, containing the individual ensemble 
  # forecasts for each site. 
  
  # Load the necessary libraries
  library(ncdf4)
  
  # Set the output filename
  outname = paste0("terrestrial-",forecast_date,"-norfolkcha.nc"
  
  # List the CABLE outputs for the forecast date
  files = list.files(paste0("outputs/",forecast_date,"/"),recursive = TRUE)
  
  for (file in files){
    # Find the ensemble member that the output is for
    ens = substr(file,25,26)
    site = substr(file,1,4)
    
  }
}