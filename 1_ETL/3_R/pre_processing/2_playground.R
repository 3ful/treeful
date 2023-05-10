################
# This is just an exploration script. We load some climate data. 
# we load some tree database
# we plot some scatters as climate hulls
if(!require(librarian)) install.packages("librarian")
library(librarian)
shelf(tidyverse, sf, osmdata, stars, raster, snow, hrbrthemes, geodata, jsonlite, tmap, R.utils)
#use multi threading
raster::beginCluster()

# set map location of your future forest
map_point <- st_as_sf(tibble(lat = 51.28672, lon = 11.01653), coords = c("lon", "lat"), crs = 4326)

##########################
# GET DATA

# Use Achille Mauris 500000 tree location dataset trees4F
trees <- readr::read_csv(file.path("2_Data/0_raw_data/EUforestspecies_AMauri.csv")) %>% 
  janitor::clean_names()

#careful, dataset is in etrs 89 LAEA, which is 3035, not 3015 as per metadata file!
trees_sf <- trees %>% 
  sf::st_as_sf(coords = c("x", "y"), crs = 3035)

# Load EU country shapes, obtained from Gisco. Useful for cropping of rasters. 
cntr <- read_sf("data/CNTR_RG_10M_2020_4326.shp", crs = 4326) %>% 
  filter(EU_STAT == "T") %>% 
  #st_transform(crs = 3015) %>% 
  filter(CNTR_ID == "DE")


####### 
#get future climate
# for now using climate projection model MPI-ESM1-2-LR and socio-econ pathway 245 
MPI_ESM1_2_LR <- geodata::cmip6_tile(model = "MPI-ESM1-2-LR", lon = 11.01684, lat = 51.28691, 
                                     ssp = "245", time = "2041-2060", var = "bioc", path = "2_Data/0_raw_data", res = 5)
# in case of 
MPI_ESM1_2_LR_de  <- raster::crop(MPI_ESM1_2_LR, cntr)


#get recent weather from dwd: 1991-2020
# for precip
download.file("https://opendata.dwd.de/climate_environment/CDC/grids_germany/multi_annual/precipitation/grids_germany_multi_annual_precipitation_1991-2020_17.asc.gz", 
              destfile = "data/DWD/prec_1991_2020.asc.gz")
R.utils::gunzip("data/DWD/prec_1991_2020.asc.gz")
dwd_1991_2020_prec <- raster("data/DWD/prec_1991_2020.asc")
crs(dwd_1991_2020_prec) <- CRS('+init=EPSG:31467')

# for temp
download.file("https://opendata.dwd.de/climate_environment/CDC/grids_germany/multi_annual/air_temperature_mean/grids_germany_multi_annual_air_temp_mean_1991_2020_17.asc.gz", 
              destfile = "data/DWD/temp_1991_2020.asc.gz")
R.utils::gunzip("data/DWD/temp_1991_2020.asc.gz")
dwd_1991_2020_temp <- raster("data/DWD/temp_1991_2020.asc")
crs(dwd_1991_2020_temp) <- CRS('+init=EPSG:31467')


# Get bioclimate data from copernicus. Download bioclimate file with login at https://cds.climate.copernicus.eu/
# bio01 is in kelvin
bio01 <- raster("data/copernicus/BIO01_era5-to-1km_1979-2018-mean_v1.0.nc")-272.15
bio01_de <- raster::crop(bio01, cntr)

# bio12 is in m/s. convert to mm/a
bio12 <- raster("data/copernicus/BIO12_era5-to-1km_1979-2018-mean_v1.0.nc")*3600*24*365*1000
bio12_de <- raster::crop(bio12, cntr)

#get future at map location
tmp_future <- raster::extract(MPI_ESM1_2_LR$lyr.1, map_point)$lyr.1
prec_future <- raster::extract(MPI_ESM1_2_LR$lyr.12,  map_point)$lyr.12
# get historic conditions from 1970-2000 worldclim.org
tmp_hist <- raster::extract(bio01, map_point)
prec_hist <- raster::extract(bio12, map_point)
# get recent conditions from dwd
# this only works for Germany. find EU-wide datasource of recent weather, 1990-2020
tmp_now <- raster::extract(dwd_1991_2020_temp, map_point)/10
prec_now <- raster::extract(dwd_1991_2020_prec, map_point)



# 
# #BIO1 is annual mean temp. downlaoding manual rasters not wokring, weird crs. use geodata package instead. much nicer
# somehow worldclim data gives strange precip values. use copernicus for now instead. 
# bio1 <- raster::raster("data/wc2.1_30s_bio_1.tif")
# bio1_europe <- raster::crop(bio1, st_bbox(cntr))
bio_de <- geodata::worldclim_tile(lat = 51.28, lon = 11.02, "bio", res = 5, path = "2_Data/0_raw_data/")
#bio_de <- geodata::worldclim_country(c("Germany"), "bio", res = 5, path = "data")


trees_sf <- trees_sf %>% 
  st_transform(crs = 4326) %>% 
  sf::st_crop(st_bbox(bio01)) 

trees_sf <- trees_sf %>% 
  mutate(temp = extract(bio01, .)) %>% 
  mutate(prec = extract(bio12, .)) 


common_trees <- group_by(trees, species_name) %>% 
  summarise(n=n()) %>% 
  arrange(desc(n)) %>% 
  slice(1:40)

trees_sf_de_enriched %>% 
  st_drop_geometry() %>% 
  filter(species_name %in% common_trees$species_name) %>% 
  ggplot() +
  geom_point(aes(x = prec, y = temp), alpha = 0.1, lwd = 0) +
  geom_point(aes(x = prec_hist, y = tmp_hist), color = "blue") +
  #geom_point(aes(x = prec_now, y = tmp_now), color = "orange") +
  geom_point(aes(x = prec_future, y = tmp_future), color = "red") +
  facet_wrap(~species_name) +
  theme_ipsum() +
  labs(title = "Avg Annual Temp and Annual Precipitation in Dornbirn", 
       subtitle = "Using Trees4F Species Presence Dataset with Copernicus Bioclimate from 1979-2018")
ggsave(filename = "figs/dornbirn_max_common40_europe.png", width = 40, height= 40)


########################### play with TRY ##################################
if (file.exists("2_Data/0_raw_data/tree_georef_3.txt") == FALSE) {
  download.file("https://cloud.toph.eu/index.php/s/tqH33KS5CNB9f6g/download/tree_georef_3.txt.zip", 
                destfile = "2_Data/0_raw_data/tree_georef_3.txt.zip")
  unzip(zipfile = "2_Data/0_raw_data/tree_georef_3.txt.zip", exdir = "2_Data/0_raw_data/")
  }


try_trees <- readr::read_delim("2_Data/0_raw_data/tree_georef_3.txt")

try_trees_sf <- try_trees %>% 
  filter(!is.na(tree_georef_1_StdValue) & !is.na(ObsData_StdValue)) %>% 
  st_as_sf(coords = c("ObsData_StdValue", "tree_georef_1_StdValue"), crs = 4326)

dplyr::select(try_trees_sf, AccSpeciesName) %>% 
  tm_shape() + tm_dots()



################### get Europe tiles of worldclim bio 1960-2000 ######################
# somehow tiles of worldclim have strange units, using global file and cropping it to Europe via ClimateEU extent

global_worldclim_files <- list.files("2_Data/0_raw_data/wc2.1_30s/", pattern = "wc2.1_30s_bio_", full.names = TRUE)
global_worldclim_name <- list.files("2_Data/0_raw_data/wc2.1_30s/", pattern = "wc2.1_30s_bio_")

for (i in 1:length(global_worldclim_files)) {
  cropped_raster <- raster::crop(raster(global_worldclim_files[i]), extent(bio_raster))
  raster::writeRaster(cropped_raster, filename = paste0("2_Data/1_output/worldclim_cropped/", global_worldclim_name[i]))
  print(i)
}

################### Give CHELSA a chance #################
global_CHELSA_files <- list.files("2_Data/0_raw_data/CHELSA//", pattern = "CHELSA", full.names = TRUE)
global_CHELSA_name <- list.files("2_Data/0_raw_data/CHELSA/", pattern = "CHELSA")

for (i in 1:length(global_CHELSA_files)) {
  cropped_raster <- raster::crop(raster(global_CHELSA_files[i]), extent(bio01))
  raster::writeRaster(cropped_raster, filename = paste0("2_Data/1_output/CHELSA_cropped/", global_CHELSA_name[i]))
  print(i)
}







### make some hulls with gbif


