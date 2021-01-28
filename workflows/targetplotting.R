# Workflow to plot the targets for the NEON forecast challenge

# Clean up
rm(list=ls())

# Load required libraries
library(lubridate)
library(ggplot2)
library(zoo)

# Read in the targets
data = read.csv("data/targets/terrestrial_30min-targets.csv")
# Extract month and day
data$month = month(data$time)
data$day = day(data$time)

# Transform the time into a datetime format, from character format
data$time = as.POSIXlt(data$time, "UTC", "%Y-%m-%dT%H:%M:%S")

# Create dataframe of daily values
data_daily <- data %>%
  mutate(time=as.Date(time, 
                      format="%Y-%m-%d")) %>%
  group_by(time,siteID, month, day) %>%               # group by the time and siteID column
  summarise("nee" = mean(nee,na.rm=TRUE),
            "le" = mean(le,na.rm=TRUE),
            "vswc" = mean(vswc,na.rm=TRUE))

# Take the mean for each day of the year
data_avgyr <- data_daily %>%
                    group_by(siteID,month,day) %>%               # group by the siteID column by day of year
                    summarise("nee" = mean(nee,na.rm=TRUE),
                              "le" = mean(le,na.rm=TRUE),
                              "vswc" = mean(vswc,na.rm=TRUE))

# Add a date column (set random year of 2000)
data_avgyr <- data_avgyr %>%
                    mutate(date = make_date(year = 2000, month, day))
# Make the average year dates a nice format
#data_avgyr$date = format(data_avgyr$date,"%b-%d")

# Rearrange dataframe to allow for nice plotting
target.df = data.frame("date"= rep(data_avgyr$date,3),
                "site" = rep(data_avgyr$siteID,3),
                "variable" = rep(c("nee","le","vswc"), each = nrow(data_avgyr)),
                "value" = c(data_avgyr$nee,data_avgyr$le,data_avgyr$vswc))

# Plot
avgyrplot = ggplot(target.df) +
            geom_point(aes(x=date,y=value,color=variable),alpha=0.5) +
            geom_smooth(aes(x=date,y=value,color = variable),span = 0.1) +
            facet_grid(variable~site, scales="free") +
            theme_bw() +
            guides(color="none")

last_plot()

save(target.df,file = "targets.Rdata")
