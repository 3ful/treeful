############ Load Packages ############ 
if(!require(librarian)) install.packages("librarian")
library(librarian)
shelf(data.table,stringr, sf, tidyverse, raster, hrbrthemes, paletteer, hexbin, RSQLite, DBI, fuzzyjoin, keyring)

# setting docker secrets as env variables to be availabe to R scripts
Sys.setenv("COPERNICUS_KEY" = read_lines("/run/secrets/copernicus_key"))
Sys.setenv("COPERNICUS_UID" = read_lines("/run/secrets/copernicus_uid"))
Sys.setenv("GBIF_EMAIL" = read_lines("/run/secrets/gbif_email"))
Sys.setenv("GBIF_PWD" = read_lines("/run/secrets/gbif_pw"))
Sys.setenv("GBIF_USER" = read_lines("/run/secrets/gbif_uid"))
Sys.setenv("POSTGRES_PW" = read_lines("/run/secrets/postgres_pw"))


# so that keyring works headless we set backend to encrypted file. twice for good measure. 
options(keyring_backend = "file")
Sys.setenv(R_KEYRING_KEYRING = "file")
# ensure no ecmwfr keyring xists
file.remove("~/.config/r-keyring/ecmwfr.keyring")
# and create keyring for ecmwfr so that keyring creation later does not prompt for password
keyring::keyring_create("ecmwfr", password = read_lines("/run/secrets/keyring_pw"))

# download raw data files, including large rasters from CDS
if (!file.exists("2_Data/0_raw_data/past/BIO01_era5-to-1km_1979-2018-mean_v1.0.nc")) {
  source("3_R/1_download_raw.R")
  cat("Downloaded Copernicus Raster files")
}

# build list of three dozen tree cadastres of european cities
source("3_R/pre_processing/0_eu_native_tree_master_list.R")

if (!file.exists("2_Data/1_output/all_merged.csv")) {
  source("3_R/pre_processing/1_harmonize_cadastres.R")
  cat("Merged various tree cadastres from around Europe and saved to disk")
}

################### get cadasters, try, trees4f and name match against master_list ####################
cat("Matching names now from various tree sources")
source("3_R/1_name_matching.R")
gc()
################### fetch GBIF #####################
if (!file.exists("2_Data/1_output/gbif_eu_trees.csv")) {
  source("3_R/2_fetch_gbif.R")
  cat("Fetched trees from GBIF")
} else {
  gbif_trees <- fread("2_Data/1_output/gbif_eu_trees.csv")
  cat("Read GBIF trees from disk")
}
gc()
################### def fun climate rasters #####################
source("3_R/3_fn_get_climate_rasters.R")


################### merge all dbs into one, extract bioclimate vars for all trees and write to postgres #####################
# this will write trees and biovars to large csv
cat("Merging all tree locations")
source("3_R/5_extract_bioclimate.R")

# to plot, run some charts in 
#rstudioapi::navigateToFile(file = "3_R/6_cross_check_climate_hulls.R")