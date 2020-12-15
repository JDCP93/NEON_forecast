#!/usr/bin/env python

"""
Generate NC file for CABLE

That's all folks.
"""
__author__ = "Martin De Kauwe"
__version__ = "1.0 (23.09.2020)"
__email__ = "mdekauwe@gmail.com"

import sys
import os
import numpy as np
import xarray as xr
import pandas as pd
import netCDF4 as nc
import datetime
import matplotlib.pyplot as plt

def main(lat, lon, df, out_fname, co2_exp="amb", vpd_exp="amb"):

    ndim = 1
    n_timesteps = len(df)
    times = []
    secs = 0.0
    for i in range(n_timesteps):
        times.append(secs)
        secs += 3600.

    # create file and write global attributes
    f = nc.Dataset(out_fname, 'w', clobber=True, format='NETCDF4')
    f.description = 'BART met data, created by Jon Page'
    f.history = "Created by: %s" % (os.path.basename(__file__))
    f.creation_date = "%s" % (datetime.datetime.now())
    f.contact = "jon.page@unsw.edu.au"

    # set dimensions
    f.createDimension('time', None)
    f.createDimension('z', ndim)
    f.createDimension('y', ndim)
    f.createDimension('x', ndim)
    #f.Conventions = "CF-1.0"

    # create variables
    time = f.createVariable('time', 'f8', ('time',))
    time.units = "seconds since %s 00:00:00" % (df.index[0])
    time.long_name = "time"
    time.calendar = "standard"

    z = f.createVariable('z', 'f8', ('z',))
    z.long_name = "z"
    z.long_name = "z dimension"

    y = f.createVariable('y', 'f8', ('y',))
    y.long_name = "y"
    y.long_name = "y dimension"

    x = f.createVariable('x', 'f8', ('x',))
    x.long_name = "x"
    x.long_name = "x dimension"

    latitude = f.createVariable('latitude', 'f8', ('y', 'x',))
    latitude.units = "degrees_north"
    latitude.missing_value = -9999.
    latitude.long_name = "Latitude"

    longitude = f.createVariable('longitude', 'f8', ('y', 'x',))
    longitude.units = "degrees_east"
    longitude.missing_value = -9999.
    longitude.long_name = "Longitude"

    SWdown = f.createVariable('SWdown', 'f8', ('time', 'y', 'x',))
    SWdown.units = "W/m^2"
    SWdown.missing_value = -9999.
    SWdown.long_name = "Surface incident shortwave radiation"
    SWdown.CF_name = "surface_downwelling_shortwave_flux_in_air"

    Tair = f.createVariable('Tair', 'f8', ('time', 'z', 'y', 'x',))
    Tair.units = "K"
    Tair.missing_value = -9999.
    Tair.long_name = "Near surface air temperature"
    Tair.CF_name = "surface_temperature"

    Rainf = f.createVariable('Rainf', 'f8', ('time', 'y', 'x',))
    Rainf.units = "mm/s"
    Rainf.missing_value = -9999.
    Rainf.long_name = "Rainfall rate"
    Rainf.CF_name = "precipitation_flux"

    Qair = f.createVariable('Qair', 'f8', ('time', 'z', 'y', 'x',))
    Qair.units = "kg/kg"
    Qair.missing_value = -9999.
    Qair.long_name = "Near surface specific humidity"
    Qair.CF_name = "surface_specific_humidity"

    Wind = f.createVariable('Wind', 'f8', ('time', 'z', 'y', 'x',))
    Wind.units = "m/s"
    Wind.missing_value = -9999.
    Wind.long_name = "Scalar windspeed" ;
    Wind.CF_name = "wind_speed"

    PSurf = f.createVariable('PSurf', 'f8', ('time', 'y', 'x',))
    PSurf.units = "Pa"
    PSurf.missing_value = -9999.
    PSurf.long_name = "Surface air pressure"
    PSurf.CF_name = "surface_air_pressure"

    LWdown = f.createVariable('LWdown', 'f8', ('time', 'y', 'x',))
    LWdown.units = "W/m^2"
    LWdown.missing_value = -9999.
    LWdown.long_name = "Surface incident longwave radiation"
    LWdown.CF_name = "surface_downwelling_longwave_flux_in_air"

    CO2air = f.createVariable('CO2air', 'f8', ('time', 'z', 'y', 'x',))
    CO2air.units = "ppm"
    CO2air.missing_value = -9999.
    CO2air.long_name = ""
    CO2air.CF_name = ""

    # write data to file
    x[:] = ndim
    y[:] = ndim
    z[:] = ndim
    time[:] = times
    latitude[:] = lat
    longitude[:] = lon

    SWdown[:,0,0] = df.swdown.values.reshape(n_timesteps, ndim, ndim)


    Rainf[:,0,0] = df.rainf.values.reshape(n_timesteps, ndim, ndim)

    if vpd_exp == "ele":
        Qair[:,0,0,0] = df.qair_future.values.reshape(n_timesteps, ndim, ndim, ndim)
    else:
        Qair[:,0,0,0] = df.qair.values.reshape(n_timesteps, ndim, ndim, ndim)

    if vpd_exp == "ele" and co2_exp == "amb":
        Tair[:,0,0,0] = df.air_temp_C_2100.values.reshape(n_timesteps, ndim,
                                                          ndim, ndim)
    elif vpd_exp == "ele" and co2_exp == "ele":
        Tair[:,0,0,0] = df.air_temp_C_2100.values.reshape(n_timesteps, ndim,
                                                          ndim, ndim)
    else:
        Tair[:,0,0,0] = df.tair.values.reshape(n_timesteps, ndim, ndim, ndim)

    Wind[:,0,0,0] = df.wind.values.reshape(n_timesteps, ndim, ndim, ndim)
    PSurf[:,0,0] = df.psurf.values.reshape(n_timesteps, ndim, ndim)
    LWdown[:,0,0] = df.lwdown.values.reshape(n_timesteps, ndim, ndim)

    if co2_exp == "ele":
        CO2air[:,0,0,0] = df.CO2_mean_ppm_2100.values.reshape(n_timesteps, ndim,
                                                              ndim, ndim)
    else:
        CO2air[:,0,0,0] = df.co2.values.reshape(n_timesteps, ndim, ndim, ndim)


    f.close()

def convert_rh_to_qair(rh, tair, press):
    """
    Converts relative humidity to specific humidity (kg/kg)

    Params:
    -------
    tair : float
        deg C
    press : float
        kPa
    rh : float
        [0-1]
    """
    tairC = tair - 273.15

    # Sat vapour pressure in Pa
    esat = calc_esat(tairC)

    # Specific humidity at saturation:
    ws = 0.622 * esat / (press - esat)

    # specific humidity
    qair = rh * ws

    return qair

def calc_esat(tair):
    """
    Calculates saturation vapour pressure

    Params:
    -------
    tair : float
        deg C

    Reference:
    ----------
    * Jones (1992) Plants and microclimate: A quantitative approach to
    environmental plant physiology, p110
    """

    esat = 613.75 * np.exp(17.502 * tair / (240.97 + tair))

    return esat

def estimate_lwdown(tair, rh):
    """
    Synthesises downward longwave radiation based on Tair RH

    Params:
    -------
    tair : float
        deg C
    rh : float
        [0-1]

    Reference:
    ----------
    * Abramowitz et al. (2012), Geophysical Research Letters, 39, L04808

    """
    zeroC = 273.15

    sat_vapress = 611.2 * np.exp(17.67 * ((tair - zeroC) / (tair - 29.65)))
    vapress = np.maximum(0.05, rh) * sat_vapress
    lw_down = 2.648 * tair + 0.0346 * vapress - 474.0

    return lw_down

def qair_to_vpd(qair, tair, press):

    """
    Qair : float
        specific humidity [kg kg-1]
    tair : float
        air temperature [deg C]
    press : float
        air pressure [kPa]
    """

    PA_TO_KPA = 0.001
    HPA_TO_PA = 100.0

    tc = tair - 273.15

    # saturation vapor pressure (Pa)
    es = HPA_TO_PA * 6.112 * np.exp((17.67 * tc) / (243.5 + tc))

    # vapor pressure
    ea = (qair * press) / (0.622 + (1.0 - 0.622) * qair)

    vpd = (es - ea) * PA_TO_KPA

    #vpd = np.where(vpd < 0.05, 0.05, vpd)

    return vpd

def vpd_to_qair(vpd, tair, press):

    KPA_TO_PA = 1000.
    HPA_TO_PA = 100.0

    tc = tair - 273.15
    # saturation vapor pressure (Pa)
    es = 611.2 * np.exp((17.67 * tc) / (243.5 + tc))

    # vapor pressure
    ea = es - (vpd * HPA_TO_PA)

    qair = 0.622 * ea / (press - (1 - 0.622) * ea)

    return qair

def convert_rh_to_qair(rh, tair, press):
    """
    Converts relative humidity to specific humidity (kg/kg)

    Params:
    -------
    tair : float
        deg C
    press : float
        Pa
    rh : float
        %
    """

    # Sat vapour pressure in Pa
    esat = calc_esat(tair)

    # Specific humidity at saturation:
    ws = 0.622 * esat / (press - esat)

    # specific humidity
    qair = (rh / 100.0) * ws

    return qair

def calc_esat(tair):
    """
    Calculates saturation vapour pressure

    Params:
    -------
    tair : float
        deg C

    Reference:
    ----------
    * Jones (1992) Plants and microclimate: A quantitative approach to
    environmental plant physiology, p110
    """

    esat = 613.75 * np.exp(17.502 * tair / (240.97 + tair))

    return esat


if __name__ == "__main__":
    forecast_date = "2020-12-13"
    siteID_list = ["BART","KONZ","OSBS","SRER"]


    for siteID in siteID_list:
        lat = 44.0639*(siteID=="BART")+31.91068*(siteID=="KONZ")+39.10077*(siteID=="OSBS")+31.91068*(siteID=="SRER")
        lon = -71.2874*(siteID=="BART")+-81.99343*(siteID=="KONZ")+-96.56309*(siteID=="OSBS")+-110.83549*(siteID=="SRER")
        fname_list = os.listdir("data/forecastcsv/"+forecast_date+"/"+siteID)
        for fname in fname_list:
            inputcsv = "data/forecastcsv/"+forecast_date+"/"+siteID+"/"+fname
            print(inputcsv)
            df = pd.read_csv(inputcsv,comment='#',na_values=-9999)

            df = df.rename(columns={'time':'dates',
                                    'Tair':'tair',
                                    'SWdown':'swdown',
                                    'Wind':'wind',
                                    'Rainf':'rainf',
                                    'PSurf':'psurf',
                                    'LWdown':'lwdown',
                                    'Qair':'qair'})

            # Clean up the dates
            df['dates'] = df['dates'].astype(str)
            new_dates = []
            for i in range(len(df)):
                year = df['dates'][i][0:4]
                month = df['dates'][i][4:6]
                day = df['dates'][i][6:8]
                hour = df['dates'][i][8:10]
                minute = df['dates'][i][10:12]
                if day.startswith("0"):
                    day = day[1:]
                if hour.startswith("0"):
                    hour = hour[1:]
                date = "%s/%s/%s %s:%s" % (year, month, day, hour, minute)
                new_dates.append(date)

            df['dates'] = new_dates
            df = df.set_index('dates')
            df.index = pd.to_datetime(df.index)

            # Add CO2
            df['co2'] = 400

            # Define names
            ens = fname[-6:-4]
            out_fname = "data/CABLEInputs/"+forecast_date+"/"+siteID+"_"+forecast_date+"_ens"+ens+"_met.nc"
            print(out_fname)
            if not os.path.exists("data/CABLEInputs/"+forecast_date):
                os.makedirs("data/CABLEInputs/"+forecast_date)

            # Create netCDF file
            main(lat, lon, df, out_fname, co2_exp="amb", vpd_exp="amb")
