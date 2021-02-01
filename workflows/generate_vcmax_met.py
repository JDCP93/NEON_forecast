
"""
Generate a new met file with a modified vcmax

"""
__author__ = "Martin De Kauwe"
__version__ = "1.0 (02.08.2018)"
__email__ = "mdekauwe@gmail.com"

import os
import sys
import glob
import shutil
import netCDF4
import subprocess
import multiprocessing as mp
import numpy as np

def ncdump(nc_fid):
    '''
    ncdump outputs dimensions, variables and their attribute information.

    Parameters
    ----------
    nc_fid : netCDF4.Dataset
        A netCDF4 dateset object

    Returns
    -------
    nc_attrs : list
        A Python list of the NetCDF file global attributes
    nc_dims : list
        A Python list of the NetCDF file dimensions
    nc_vars : list
        A Python list of the NetCDF file variables
    '''

    # NetCDF global attributes
    nc_attrs = nc_fid.ncattrs()
    nc_dims = [dim for dim in nc_fid.dimensions]  # list of nc dimensions

    # Variable information.
    nc_vars = [var for var in nc_fid.variables]  # list of nc variables

    return nc_attrs, nc_dims, nc_vars

def change_vcmax(met_fname, vcmax25):

    new_met_fname = "%s_vcmax_%s.nc" % (met_fname[:-7], vcmax25)

    shutil.copyfile(met_fname, new_met_fname)

    nc = netCDF4.Dataset(new_met_fname, 'r+')
    (nc_attrs, nc_dims, nc_vars) = ncdump(nc)

    vcmax = nc.createVariable('vcmax', 'f8', ('y', 'x'))
    vcmax[:] = vcmax25 * 1e-6

    nc.close()  # close the new file


if __name__ == "__main__":

    #------------- Change stuff ------------- #
    forecast_date = "2021-01-01"
    siteID = "SRER"
    vcmax = 100.
    met_dir = "data/CABLEInputs/tests/"+forecast_date+"/"+siteID
    met_subset = []
    # ------------------------------------------- #

if len(met_subset) == 0:
    met_files = glob.glob(os.path.join(met_dir, "*.nc"))
else:
    met_files = [os.path.join(met_dir, i) for i in met_subset]

for fname in met_files:
    change_vcmax(fname, vcmax)
