#################### Trees4F from figshare ###################
if (!file.exists("2_Data/0_raw_data/EUforestspecies_AMauri.csv")) {
  download.file("https://springernature.figshare.com/ndownloader/files/6662535", destfile = "2_Data/0_raw_data/EUforestspecies_AMauri.csv")
}

#################### COPERNICUS CDS Download ###################
# REGISTER YOURSELF AND ENTER DETAILS FROM HERE:
# https://cds.climate.copernicus.eu/user/register
# Beware the user is the UID at the bottom of your user page.

uid <- Sys.getenv("COPERNICUS_UID")

wf_set_key(user=uid, # 
           key=Sys.getenv("COPERNICUS_KEY"), 
           service="cds")

request <- list(
  region = "europe",
  variable = c("annual_mean_temperature", "annual_precipitation", "isothermality", "maximum_temperature_of_warmest_month", "mean_diurnal_range", "mean_temperature_of_coldest_quarter", "mean_temperature_of_driest_quarter", "mean_temperature_of_warmest_quarter", "mean_temperature_of_wettest_quarter", "minimum_temperature_of_coldest_month", "precipitation_of_coldest_quarter", "precipitation_of_driest_month", "precipitation_of_driest_quarter", "precipitation_of_warmest_quarter", "precipitation_of_wettest_month", 
"precipitation_of_wettest_quarter", "precipitation_seasonality", "temperature_annual_range", "temperature_seasonality", "volumetric_soil_water"),
  derived_variable = "annual_mean",
  model = "hadgem2_cc",
  ensemble_member = "r1i1p1",
  experiment = "rcp4_5",
  statistic = "mean",
  version = "1.0",
  format = "zip",
  dataset_short_name = "sis-biodiversity-cmip5-regional",
  target = "download.zip"
)

ncfile <- wf_request(
  user = uid,
  request = request,   
  transfer = TRUE,  
  path = "2_Data/0_raw_data/future",
  verbose = FALSE
)


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
  user = uid,
  request = request,   
  transfer = TRUE,  
  path = "2_Data/0_raw_data/past",
  verbose = FALSE
)


if (file.exists("2_Data/0_raw_data/past/download.zip")) {
  utils::unzip("2_Data/0_raw_data/past/download.zip", exdir = "2_Data/0_raw_data/past/")
  file.remove("2_Data/0_raw_data/past/download.zip")
}
if (file.exists("2_Data/0_raw_data/future/download.zip")) {
  utils::unzip("2_Data/0_raw_data/future/download.zip", exdir = "2_Data/0_raw_data/future/")
  file.remove("2_Data/0_raw_data/future/download.zip")
}


