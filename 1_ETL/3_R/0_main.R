############ Load Packages ############ 
if(!require(librarian)) install.packages("librarian")
library(librarian)
shelf(data.table,stringr, sf, tidyverse, raster, hrbrthemes, paletteer, hexbin, RSQLite, DBI, fuzzyjoin)

################## get raster files from copernicus ###########
# set your api key in start.py

# tell reticulate to use venv in this repo
reticulate::virtualenv_python("4_venv/")
# run python script to check if raster files exist locally, otherwise will be fetchen from CDS. 
# They need to be generated from CDS for a while. and then will be downloaded. 
reticulate::py_run_file("start.py")
if (file.exists("2_Data/0_raw_data/copernicus/download.zip")) {
  utils::unzip("2_Data/0_raw_data/copernicus/download.zip")
}
if (file.exists("2_Data/0_raw_data/copernicus/future/download.zip")) {
  utils::unzip("2_Data/0_raw_data/copernicus/future/download.zip")
}


################### get cadasters, try, trees4f and name match against master_list ####################
source("3_R/1_name_matching.R")
################### fetch GBIF #####################
source("3_R/2_fetch_gbif.R")
################### def fun climate rasters #####################
source("3_R/3_fn_get_climate_rasters.R")

################### get user input location climate ####################
# source("3_R/4_fn_user_location.R")
# user_climate1 <- get_user_climate()
# user_climate2 <- get_user_climate(lat = 53.1180, lon = 8.8261)

################### merge all dbs into one, extract bioclimate vars for all trees and write to sqlite #####################
# this will write trees and biovars to large csv
source("3_R/5_extract_bioclimate.R")

# to plot, run some charts in 
rstudioapi::navigateToFile(file = "3_R/6_cross_check_climate_hulls.R")