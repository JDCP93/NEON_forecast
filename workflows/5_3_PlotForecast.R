PlotForecast = function(forecast_date){
  
  # Source libraries
  library(ggplot2)
  library(cowplot)
  
  # Load the saved data
  name = paste0("terrestrial_daily-",forecast_date,"-norfolkcha.Rdata")
  load(eval(name))
  
  # Rearrange data.frame to allow for plotting
  df = data.frame("time" = rep(SiteMean$time),
                  "site" = rep(SiteMean$site),
                  "variable" = rep(c("nee","vswc","le"), each = nrow(SiteMean)),
                  "mean" = c(SiteMean$nee_mean,SiteMean$vswc_mean,SiteMean$le_mean),
                  "sd" = c(SiteMean$nee_sd,SiteMean$vswc_sd,SiteMean$le_sd))
  
  # Plot each variable, gridded by site with -/+ sd as ribbon
  neePlot = ggplot(df[df$variable == "nee",]) +
            geom_path(aes(x=time,y = mean, color = site)) +
            geom_ribbon(aes(x=time,
                            ymin=mean-sd,
                            ymax=mean+sd,
                            fill = site),
                        alpha = 0.5) +
            facet_grid(site~variable) +
            coord_cartesian(ylim=c(-5,2)) +
            theme_bw() +
            guides(color = "none",fill = "none")
  
  vswcPlot = ggplot(df[df$variable == "vswc",]) +
              geom_path(aes(x=time,y = mean, color = site)) +
              geom_ribbon(aes(x=time,
                              ymin=mean-sd,
                              ymax=mean+sd,
                              fill = site),
                          alpha = 0.5) +
              facet_grid(site~variable) +
              coord_cartesian(ylim=c(0,0.4)) +
              theme_bw() +
              guides(color = "none",fill = "none")
  
  lePlot = ggplot(df[df$variable == "le",]) +
            geom_path(aes(x=time,y = mean, color = site)) +
            geom_ribbon(aes(x=time,
                            ymin=mean-sd,
                            ymax=mean+sd,
                            fill = site),
                        alpha = 0.5) +
            facet_grid(site~variable) +
            coord_cartesian(ylim=c(0,210)) +
            theme_bw() +
            guides(color = "none",fill = "none")

  # Combine into one figure
  plot_main = plot_grid(neePlot,lePlot,vswcPlot, ncol = 3)
  
  # Add forecast_date as title
  title = ggdraw() + 
          draw_label(forecast_date,fontface = 'bold',x = 0,hjust = 0) +
          theme(plot.margin = margin(0, 0, 0, 50))
  
  plot = plot_grid(title, plot_main,ncol = 1,rel_heights = c(0.05, 1))
  
  # Save plot
  name = paste0(forecast_date,"_ForecastPlots.png")
  ggsave(name,plot,device = "png")
}