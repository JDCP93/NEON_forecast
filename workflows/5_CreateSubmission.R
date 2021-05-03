
# Make sure environment is empty
rm(list=ls())

# Source required libraries
library(lubridate)

# Define parameters
forecast_date = "2021-04-01"
team_name = "norfolkcha"

# Generate the submission in a csv format
source("workflows/5-1_GenerateSubmissionCSV.R")
NEONSubmission(forecast_date)

forecast_file_name_base <- paste0("terrestrial_daily-",forecast_date,"-",team_name)
forecast_file <- paste0(forecast_file_name_base, ".csv")

# Generate metadata

curr_time <- with_tz(Sys.time(), "UTC")
#forecast_issue_time <- format(curr_time,format = "%Y-%m-%d %H:%M:%SZ", usetz = F)
forecast_issue_time <- as_date(curr_time)
forecast_iteration_id <- forecast_date
forecast_model_id <- team_name

source("workflows/5-2_GenerateMetadata.R")
meta_data_filename <- generate_metadata(forecast_file =  forecast_file,
                                        metadata_yaml = "data/metadata.yml",
                                        forecast_issue_time = as_date(with_tz(Sys.time(), "UTC")),
                                        forecast_iteration_id = forecast_date,
                                        forecast_file_name_base = forecast_file_name_base)


# Save a plot of the results for comparison with previous forecasts and for
# sanity checks
source("workflows/5-3_PlotForecast.R")
PlotForecast(forecast_date)
