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

if __name__ == "__main__":

    forecast_date = "2021-01-01"
    siteID = "OSBS"
    fname = "data/AmeriFlux/raw/AMF_US-SP1_BASE-BADM_4-1/AMF_US-SP1_BASE_HH_4-1.csv"

    # Open AmeriFlux data
    df = pd.read_csv(fname,comment='#',na_values=-9999)
    # rename columns
    df = df.rename(columns={'TIMESTAMP_START':'dates',
                            'TA':'tair',
                            'RH':'rh',
                            'SW_IN':'swdown',
                            'WS':'wind',
                            'P':'rainf',
                            'VPD_PI':'vpd',
                            'CO2_1':'co2'})

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

    # re-index df
    df['dates'] = new_dates
    df = df.set_index('dates')
    df.index = pd.to_datetime(df.index)

    # fix units
    kpa_2_pa = 1000.
    deg_2_kelvin = 273.15
    df.tair += deg_2_kelvin
    df.rainf /= 1800. # kg m-2 s-1

    # sort out bad values
    df.swdown = np.where(df.swdown < 0.0, 0.0, df.swdown)
    df.vpd = np.where(df.vpd <= 0.05, 0.05, df.vpd)
    df.rainf = np.where(df.rainf <= 0, 0, df.rainf)

    # Calculate the mean climatology from the data
    meandf = df.groupby([df.index.month, df.index.day]).mean()
    # Put this into imaginary year 2000 (a leap year)
    new_dates = []
    for i in range(len(meandf.index)):
        month = meandf.index[i][0]
        day = meandf.index[i][1]
        date = "2000-%s-%s" % (month, day)
        date = datetime.strptime(date, "%Y-%m-%d")
        new_dates.append(date)

    meandf['date'] = new_dates
    meandf = meandf.set_index('date')

    # Create an index of fake dates
    fakedates = pd.date_range(start="2015-01-01",end=forecast_date,freq='1H', closed='left')
    # Define new dataframe
    newdf = pd.DataFrame({"time" : fakedates,
                     "tair" : np.NaN,
                     "rh" : np.NaN,
                     "swdown" : np.NaN,
                     "wind" : np.NaN,
                     "rainf" : np.NaN,
                     "vpd" : np.NaN,
                     "co2" : np.NaN})

    # Fill new dataframe with averages
    for var in ['swdown','tair','rh', 'wind', 'rainf', 'vpd', 'co2']:
        for i in range(len(newdf)):
            month = newdf['time'][i].month
            day = newdf['time'][i].day
            raw = meandf[var][np.logical_and(meandf.index.month == month , meandf.index.day == day)]
            value = raw.values
            newdf.loc[i, var] = value

    # Add pressure
    newdf['psurf'] = 101325

    # Add LW
    newdf['lwdown'] = estimate_lwdown(newdf.tair.values, newdf.rh.values/100.)

    # Add qair
    newdf['qair'] = vpd_to_qair(newdf.vpd.values, newdf.tair.values, newdf.psurf.values)

    # Remove some rainfall values
    newdf.rainf = np.where(newdf.rainf <= 0.00001, 0, newdf.rainf)

    # Set CO2 to 390 if NaN
    newdf.co2 = np.where((newdf.co2).isna(), 390, newdf.co2)

    # Define name
    out_fname = "data/averagemet/"+siteID+"_"+forecast_date+".csv"
    # Save file
    newdf.to_csv(out_fname,index=False)
