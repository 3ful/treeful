For a good walkthrough see here:
# https://cran.r-project.org/web/packages/ecmwfr/vignettes/cds_vignette.html

if(!require(librarian)) install.packages("librarian")
library(librarian)
shelf(data.table,ecmwfr,keyring)

# REGISTER YOURSELF AND ENTER DETAILS FROM HERE:
# https://cds.climate.copernicus.eu/user/register
# Beware the user is the UID at the bottom of your user page.
wf_set_key(user="ADD_YOUR_USER_ID_HERE", # 
           key="ADD_YOUR_USER_API_KEY_HERE", 
           service="cds")


request <- list(
  region = "europe",
  origin = "era5",
  variable = c("annual_mean_temperature", "annual_precipitation", "isothermality", "maximum_temperature_of_warmest_month", "mean_diurnal_range", "mean_temperature_of_coldest_quarter", "mean_temperature_of_driest_quarter", "mean_temperature_of_warmest_quarter", "mean_temperature_of_wettest_quarter", "minimum_temperature_of_coldest_month", "precipitation_of_coldest_quarter", "precipitation_of_driest_month", "precipitation_of_driest_quarter", "precipitation_of_warmest_quarter", "precipitation_of_wettest_month", 
"precipitation_of_wettest_quarter", "precipitation_seasonality", "temperature_annual_range", "temperature_seasonality", "volumetric_soil_water"),
  derived_variable = "annual_mean",
  statistic = "mean",
  version = "1.0",
  format = "zip",
  dataset_short_name = "sis-biodiversity-era5-regional",
  target = "download.zip"
)

ncfile <- wf_request(
  user = "197485",
  request = request,   
  transfer = TRUE,  
  path = "2_Data/0_raw_data/copernicus/future/BIO01_hadgem2-cc_rcp45_r1i1p1_1960-2099-mean_v1.0.nc",
  verbose = FALSE
)
