
rm(list=ls())
source("workflows/2_2_CheckNEONMet.R")

# Let's check the met files for sanity
plot_BART = CheckNEONMet("BART","2021-01-01")
plot_BART

plot_KONZ = CheckNEONMet("KONZ","2021-01-01")
plot_KONZ

plot_OSBS = CheckNEONMet("OSBS","2021-01-01")
plot_OSBS

plot_SRER = CheckNEONMet("SRER","2021-01-01")
plot_SRER



# Check the rainfall totals 
# Should be 330mm per year
sum(plot_SRER$data$value[plot_SRER$data$variable=="rainf"])
# Should be 1245mm per year
sum(plot_BART$data$value[plot_BART$data$variable=="rainf"])
# Should be 867mm per year
sum(plot_KONZ$data$value[plot_KONZ$data$variable=="rainf"])
# Should be 1309mm per year
sum(plot_OSBS$data$value[plot_OSBS$data$variable=="rainf"])


## Now let's check the CABLE outputs

library(lubridate)
library(magrittr)
library(tidyverse)

# Source the function that compiles the outputs
source("workflows/5_1_GenerateSubmissionNetCDF.R")
data = NEONSubmission("2021-01-01")
# Create dataframe of daily values and QC counts
Data_day <- data %>%
  mutate(time=as.Date(time, 
                      format="%Y-%m-%d")) %>%
  group_by(time,site,ensemble) %>%               # group by the day column
  summarise(nee = mean(nee),
            gpp = mean(gpp),
            le=mean(le),
            vswc=mean(vswc))

Data_day = Data_day[Data_day$time>="2020-01-01",]

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

# Cut out just the last year (since previous 4 years are exactly the same)
SiteMean = SiteMean[SiteMean$time>="2020-01-01",]

# Create dataframe allowing nice plotting
CABLE.df = data.frame("time" = rep(SiteMean$time,4),
                "site" = rep(SiteMean$site,4),
                "variable" = rep(c("nee","gpp","le","vswc"), each = nrow(SiteMean)),
                "mean" = c(SiteMean$nee_mean,SiteMean$gpp_mean,SiteMean$le_mean,SiteMean$vswc_mean),
                "sd" = c(SiteMean$nee_sd,SiteMean$gpp_sd,SiteMean$le_sd,SiteMean$vswc_sd))

# Load the target data - called target.df
load("data/targets/targets.Rdata")

# Lets combine them into one df
# First we remove the unneeded data from CABLE.df
CABLE.df_target = CABLE.df[CABLE.df$time<"2021-01-01" & CABLE.df$variable != "gpp",]
plot.df = data.frame("time" = target.df$time,
                     "site" = target.df$site,
                     "variable" = target.df$variable,
                     "model_mean" = CABLE.df_target$mean,
                     "model_sd" = CABLE.df_target$sd,
                     "target_mean" = target.df$mean,
                     "target_sd" = target.df$sd)

# Now we plot them!

compareplot = ggplot(plot.df) +
              geom_line(aes(x=time,y=target_mean,color=variable),size=2,alpha=0.5) +
              geom_line(aes(x=time,y=model_mean)) +
              facet_grid(variable~site, scales="free") +
              theme_bw() +
              guides(color="none")

last_plot()

