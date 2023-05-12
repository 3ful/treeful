#!/1_ETL/4_venv/bin/python
import cdsapi
import os

c = cdsapi.Client(url='https://cds.climate.copernicus.eu/api/v2', key=os.environ.get('COPERNICUS_KEY'))

# Specify path
path = '2_Data/0_raw_data/copernicus/BIO01_era5-to-1km_1979-2018-mean_v1.0.nc'
 
# Check whether the specified
# path exists or not
isExist = os.path.exists(path)

if isExist:
  exit
else:
  c.retrieve(
      'sis-biodiversity-era5-regional',
      {
          'region': 'europe',
          'origin': 'era5',
          'variable': [
              'annual_mean_temperature', 'annual_precipitation', 'isothermality',
              'maximum_temperature_of_warmest_month', 'mean_diurnal_range', 'mean_temperature_of_coldest_quarter',
              'mean_temperature_of_driest_quarter', 'mean_temperature_of_warmest_quarter', 'mean_temperature_of_wettest_quarter',
              'minimum_temperature_of_coldest_month', 'precipitation_of_coldest_quarter', 'precipitation_of_driest_month',
              'precipitation_of_driest_quarter', 'precipitation_of_warmest_quarter', 'precipitation_of_wettest_month',
              'precipitation_of_wettest_quarter', 'precipitation_seasonality', 'temperature_annual_range',
              'temperature_seasonality', 'volumetric_soil_water',
          ],
          'derived_variable': 'annual_mean',
          'statistic': 'mean',
          'version': '1.0',
          'format': 'zip',
      },
      '2_Data/0_raw_data/copernicus/download.zip')
  
  
  
path = '2_Data/0_raw_data/copernicus/future/BIO01_hadgem2-cc_rcp45_r1i1p1_1960-2099-mean_v1.0.nc'
isExist = os.path.exists(path)

if isExist:
  exit
else:
  c.retrieve(
      'sis-biodiversity-cmip5-regional',
      {
          'region': 'europe',
          'variable': [
              'annual_mean_temperature', 'annual_precipitation', 'isothermality',
              'maximum_temperature_of_warmest_month', 'mean_diurnal_range', 'mean_temperature_of_coldest_quarter',
              'mean_temperature_of_driest_quarter', 'mean_temperature_of_warmest_quarter', 'mean_temperature_of_wettest_quarter',
              'minimum_temperature_of_coldest_month', 'precipitation_of_coldest_quarter', 'precipitation_of_driest_month',
              'precipitation_of_driest_quarter', 'precipitation_of_warmest_quarter', 'precipitation_of_wettest_month',
              'precipitation_of_wettest_quarter', 'precipitation_seasonality', 'temperature_annual_range',
              'temperature_seasonality', 'volumetric_soil_water',
          ],
          'derived_variable': 'annual_mean',
          'model': 'hadgem2_cc',
          'ensemble_member': 'r1i1p1',
          'experiment': 'rcp4_5',
          'statistic': 'mean',
          'version': '1.0',
          'format': 'zip',
      },
      '2_Data/0_raw_data/copernicus/future/download.zip')
