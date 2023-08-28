setwd("1_ETL/")
source("3_R/00_setup.R")
# so that keyring works headless we set backend to encrypted file. twice for good measure. 
options(keyring_backend = "file")
Sys.setenv(R_KEYRING_KEYRING = "file")
# ensure no ecmwfr keyring xists
if (file.exists("~/.config/r-keyring/ecmwfr.keyring")) {
  file.remove("~/.config/r-keyring/ecmwfr.keyring")
}
# and create keyring for ecmwfr so that keyring creation later does not prompt for password
keyring::keyring_create("ecmwfr", password = read_lines("/run/secrets/keyring_pw"))

# download raw data files, including large rasters from CDS

# open postgis connection
con <- backend_con()

if (!file.exists("2_Data/0_raw_data/past/BIO01_era5-to-1km_1979-2018-mean_v1.0.nc")) {
  source("3_R/1_download_raw.R")
  sendstatus("Downloaded Copernicus Raster files")
} else {
  sendstatus("No need to download CDS raster files, Files exist on disk. ")
}
DBI::dbDisconnect(conn = con)

# build list of three dozen tree cadastres of european cities
if (!file.exists("2_Data/1_output/all_merged.csv")) {
  source("3_R/pre_processing/1_harmonize_cadastres.R")
  sendstatus("Merged various tree cadastres from around Europe and saved to disk")
}

################### get cadasters, try, trees4f and name match against master_list ####################
sendstatus("Matching names now from various tree sources")
source("3_R/1_name_matching.R")
gc()
################### fetch GBIF #####################
if (!file.exists("2_Data/1_output/gbif_eu_trees.csv")) {
  source("3_R/2_fetch_gbif.R")
  sendstatus("Fetched trees from GBIF")
} else {
  gbif_trees <- fread("2_Data/1_output/gbif_eu_trees.csv")
  sendstatus("Read GBIF trees from disk")
}
gc()
################### def fun climate rasters #####################
source("3_R/3_fn_get_climate_rasters.R")


################### merge all dbs into one, extract bioclimate vars for all trees and write to postgres #####################
# this will write trees and biovars to large csv and to postgres
sendstatus("Merging all tree locations")
source("3_R/5_extract_bioclimate.R")
gc()

## writing rasters to postgres
#cat("writing all to postgres")
#source("3_R/6_write_to_db.R")

## writing wikipedia-enriched master db to postgres
cat("writing all to postgres")
source("3_R/7_get_tree_vernaculars.R")

###### EOF ####
