
rm(list=ls())
source("workflows/metcheck.R")

# Let's check the met files for sanity
plot_BART = metcheck("BART","2021-01-01")
plot_BART

plot_KONZ = metcheck("KONZ","2021-01-01")
plot_KONZ

plot_OSBS = metcheck("OSBS","2021-01-01")
plot_OSBS

plot_SRER = metcheck("SRER","2021-01-01")
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
source("NEONSubmission.R")
data = NEONSubmission("2021-01-01")
# Create dataframe of daily values and QC counts
Data_day <- data %>%
  mutate(time=as.Date(time, 
                      format="%Y-%m-%d")) %>%
  group_by(time,site,ensemble) %>%               # group by the day column
  summarise(nee = sum(nee),
            gpp = sum(gpp),
            le=mean(le),
            vswc=mean(vswc))


# Group by site - i.e. ensemble means
ensemblemean = Data_day %>%
  group_by(time,site) %>%
  summarise(nee = mean(nee),
            gpp = mean(gpp),
            le=mean(le),
            vswc=mean(vswc))

# Cut out just the last year (since previous 4 years are exactly the same)
ensemblemeanforecast = ensemblemean[ensemblemean$time>="2020-01-01",]

# Plot nee, gpp and le
plot = ggplot(ensemblemeanforecast) +
  geom_line(aes(time,nee,color = site),size=2)

plot

plot = ggplot(ensemblemeanforecast) +
  geom_line(aes(time,gpp,color = site),size=2)

plot

plot = ggplot(ensemblemeanforecast) +
  geom_line(aes(time,le,color = site),size=1.2)

plot
