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
from datetime import datetime
import matplotlib.pyplot as plt
from itertools import groupby
import statistics

def rh_to_qair(rh, tair, press):
    """
    Converts relative humidity to specific humidity (kg/kg)

    Params:
    -------
    tair : float
        Kelvin
    press : float
        kPa
    rh : float
        [0-100]
    """
    tairC = tair - 273.15

    # Sat vapour pressure in Pa
    esat = calc_esat(tairC)

    # Specific humidity at saturation:
    ws = 0.622 * esat / (press - esat)

    # specific humidity
    qair = rh/100 * ws

    return qair

def qair_to_vpd(qair, tair, press):

    """
    Qair : float
        specific humidity [kg kg-1]
    tair : float
        air temperature [kelvin]
    press : float
        air pressure [kPa]
    """

    # Convert units
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

    forecast_date = "2021-02-01"
    siteID = "BART"
    fname = "data/NEON/raw/NEONMetFile_BART_2021-01-31.csv"

    # Open AmeriFlux data
    df = pd.read_csv(fname,comment='#',na_values=-9999)
    # rename columns
    df = df.rename(columns={'time':'dates',
                            'tempSingleMean':'tair',
                            'RHMean':'rh',
                            'inSWMean':'swdown',
                            'windSpeedMean':'wind',
                            'TFPrecipBulk':'rainf',
                            'inLWMean':'lwdown',
                            'staPresMean':'psurf'})

    # Clean up the dates
    df['dates'] = df['dates'].astype(str)
    new_dates = []
    for i in range(len(df)):
        year = df['dates'][i][0:4]
        month = df['dates'][i][5:7]
        day = df['dates'][i][8:10]
        hour = df['dates'][i][11:13]
        minute = df['dates'][i][14:16]
        if day.startswith("0"):
            day = day[1:]
        if hour.startswith("0"):
            hour = hour[1:]
        date = "%s/%s/%s %s:%s" % (year, month, day, hour, minute)
        new_dates.append(date)

    # re-index df
    df['dates'] = new_dates
    df = df.set_index('dates')
    df.index = pd.to_datetime(df.index)

    # fix units
    kpa_2_pa = 1000.
    deg_2_kelvin = 273.15
    df.tair += deg_2_kelvin
    df.rainf /= 3600. # kg m-2 s-1
    df.psurf *= kpa_2_pa

    # sort out bad values
    df.swdown = np.where(df.swdown < 0.0, 0.0, df.swdown)
    df.rainf = np.where(df.rainf <= 0, 0, df.rainf)

    # Add qair
    df['qair'] = rh_to_qair(df.rh.values, df.tair.values, df.psurf.values)

    # Calculate vpd
    df['vpd'] = qair_to_vpd(df.qair.values, df.tair.values, df.psurf.values)

    # Define name
    out_fname = "data/NEON/processed/"+siteID+"_"+forecast_date+".csv"
    # Save file
    df.to_csv(out_fname)
