# Clean
rm(list=ls())

# Source scripts
source("workflows/1-1_NEONDataDownload.R")
source("workflows/1-2_GenerateMetData.R")
source("workflows/1-3_NOAAdownload.R")
source("workflows/1-4_GenerateForecastCSV.R")

#############################################
#                                           #
#   !!! MOVE EXISTING DATA TO ARCHIVE !!!   #
#                                           # 
#############################################

# Set parameters
Sites = c("BART","KONZ","OSBS","SRER")
forecast_date = "2021-06-01"

# Download latest NEON observations
NEONDataDownload(Sites,forecast_date)

# Generate previous met data
for (Site in Sites){
  GenerateMetData(Site,forecast_date)
}

# Download forecasts
for (Site in Sites){
download_noaa_files_s3(Site, forecast_date, "00", "data/")
}

# Turn forecast netCDFs into CSV files
for (Site in Sites){
  GenerateForecastCSV(Site, forecast_date)
}
