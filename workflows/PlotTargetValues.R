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
                    group_by(month,day,siteID) %>%               # group by the siteID column by day of year
                    summarise("nee_mean" = mean(nee,na.rm=TRUE),
                              "le_mean" = mean(le,na.rm=TRUE),
                              "vswc_mean" = mean(vswc,na.rm=TRUE),
                              "nee_sd" = sd(nee,na.rm=TRUE),
                              "le_sd" = sd(le,na.rm=TRUE),
                              "vswc_sd" = sd(vswc,na.rm=TRUE))

# Add a date column (set random year of 2000)
data_avgyr <- data_avgyr %>%
                    mutate(time = make_date(year = 2000, month, day))
# Make the average year dates a nice format
#data_avgyr$date = format(data_avgyr$date,"%b-%d")

# Rearrange dataframe to allow for nice plotting
target.df = data.frame("time"= rep(data_avgyr$time,3),
                "site" = rep(data_avgyr$siteID,3),
                "variable" = rep(c("nee","le","vswc"), each = nrow(data_avgyr)),
                "mean" = c(data_avgyr$nee_mean,data_avgyr$le_mean,data_avgyr$vswc_mean),
                "sd" = c(data_avgyr$nee_sd,data_avgyr$le_sd,data_avgyr$vswc_sd))

# Plot
avgyrplot = ggplot(target.df) +
            geom_ribbon(aes(x=time,ymin=mean-sd,ymax=mean+sd),alpha=0.5) +
            geom_point(aes(x=time,y=mean,color=variable)) +
            facet_grid(variable~site, scales="free") +
            theme_bw() +
            guides(color="none")

last_plot()

save(target.df,file = "data/targets/targets.Rdata")
