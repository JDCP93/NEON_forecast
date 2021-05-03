# Clean
rm(list=ls())

# Source scripts
source("workflows/0_NEONDataDownload.R")
source("workflows/1-1_GenerateMetData.R")
source("workflows/1-2_NOAAdownload.R")
source("workflows/1-3_GenerateForecastCSV.R")

#############################################
#                                           #
#   !!! MOVE EXISTING DATA TO ARCHIVE !!!   #
#                                           # 
#############################################

# Set parameters
Sites = c("BART","KONZ","OSBS","SRER")
forecast_date = "2021-04-01"

# Download latest NEON observations
NEONDataDownload(Sites)

# Generate previous met data
for (Site in Sites){
  GenerateMetData(Site)
}

# Download forecasts
for (Site in Sites){
download_noaa_files_s3(Site, forecast_date, "00", "data/")
}

# Turn forecast netCDFs into CSV files
for (Site in Sites){
  GenerateForecastCSV(Site, forecast_date)
}
