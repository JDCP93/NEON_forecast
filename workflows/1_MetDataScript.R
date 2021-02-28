# Clean
rm(list=ls())

# Source scripts
source("workflows/GenerateMetData.R")
source("workflows/NOAAdownload.R")
source("workflows/GenerateForecastCSV.R")

# Set parameters
Sites = c("BART","KONZ","OSBS","SRER")
forecast_date = "2021-02-01"

# Generate previous met data
for (Site in Sites){
  GenerateMetData(Site)
}

# Download forecasts
for (Site in Sites){
download_noaa_files_s3(Site, forecast_date, "00", "data/")
}

# Create CSV of observed + forecast data
for (Site in Sites){
  GenerateForecastCSV(Site, forecast_date)
}
