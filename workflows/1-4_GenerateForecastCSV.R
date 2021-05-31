GenerateForecastCSV <- function(siteID,date){
  message("Formatting forecast data for ",siteID," as csv")
  for (ens in sprintf("%02d", 1:30)){
    library(ncdf4)
    # Open the ensemble member forecast
    data = nc_open(paste0("data/noaa/NOAAGEFS_1hr/",
                          siteID,
                          "/",
                          date,
                          "/00/NOAAGEFS_1hr_",
                          siteID,
                          "_",
                          date,
                          "T00_",
                          as.Date(date)+35,
                          "T00_ens",
                          ens,
                          ".nc"))
    # Read it into a dataframe
    # Convert time into datetimes
    time = ncvar_get(data,"time")
    time_from = substr(ncatt_get(data, "time")$units, 13, 30)
    Hours_to_Secs = 3600
    time = as.POSIXct(time*Hours_to_Secs, origin=time_from, tz = "UTC")
    time = format(time,"%Y%m%d%H%M")
    df = data.frame("time" = time)
    df = cbind(df,
               "Tair" = ncvar_get(data,"air_temperature"),
               "PSurf" = ncvar_get(data,"air_pressure"),
               "Rainf" = ncvar_get(data,"precipitation_flux"),
               "Qair" = ncvar_get(data,"specific_humidity"),
               "LWdown" = ncvar_get(data,"surface_downwelling_longwave_flux_in_air"),
               "SWdown" = ncvar_get(data,"surface_downwelling_shortwave_flux_in_air"),
               "Wind" = ncvar_get(data,"wind_speed")
               )
    dir = paste0("data/forecastcsv/",
                 date,
                 "/",
                 siteID
                 )
    name = paste0(dir,
                  "/",
                  siteID,
                  "_",
                  date,
                  "_",
                  as.Date(date)+35,
                  "_ens",
                  ens,
                  ".csv")
    
    if (dir.exists(dir)){
    } else {
      dir.create(dir, showWarnings = FALSE, recursive = TRUE)
    }
    
    write.csv(df,file = name, row.names = FALSE)
  
  }
  
}