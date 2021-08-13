# Download files within date range from NOAA carbontracker; Current files available are from 01/01/2000 - 03/29/2019

import urllib.request
import pandas as pd
from datetime import date,timedelta

sdate = date(2000,3,22)
edate = date(2000,4,9) 

date_list = [str(i)[:10] for i in pd.date_range(sdate,edate-timedelta(days=1),freq='d')]

for d in date_list:
    print('Downloading file for %s'%(d))
    url = 'https://gml.noaa.gov/aftp/products/carbontracker/co2/molefractions/co2_total/CT2019B.molefrac_glb3x2_%s.nc'%(d)
    urllib.request.urlretrieve(url,'CT2019B.molefrac_glb3x2_%s.nc'%(d))

