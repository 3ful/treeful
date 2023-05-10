#################### LOad DBs, merge, turn into SF, extract bioclim #############################


bio01_copernicus <- getpastclimate(source = "copernicus", bioclim = "bio01")
bio12_copernicus <- getpastclimate(source = "copernicus", bioclim = "bio12")
bio01_chelsa <- getpastclimate(source = "chelsa", bioclim = "bio01")
bio12_chelsa <- getpastclimate(source = "chelsa", bioclim = "bio12")
bio01_worldclim <- getpastclimate(source = "worldclim", bioclim = "bio01")
bio12_worldclim <- getpastclimate(source = "worldclim", bioclim = "bio12")
print("I just obtained some bio rasters")

# bio02 <- getpastclimate(source = "worldclim", bioclim = "bio02")
# bio03 <- getpastclimate(source = "worldclim", bioclim = "bio03")
# bio04 <- getpastclimate(source = "worldclim", bioclim = "bio04")
# bio05 <- getpastclimate(source = "worldclim", bioclim = "bio05")
# bio06 <- getpastclimate(source = "worldclim", bioclim = "bio06")
# bio07 <- getpastclimate(source = "worldclim", bioclim = "bio07")
# bio08 <- getpastclimate(source = "worldclim", bioclim = "bio08")
# bio09 <- getpastclimate(source = "worldclim", bioclim = "bio09")
# bio10 <- getpastclimate(source = "worldclim", bioclim = "bio10")
# bio11 <- getpastclimate(source = "worldclim", bioclim = "bio11")

# bio13 <- getpastclimate(source = "worldclim", bioclim = "bio13")
# bio14 <- getpastclimate(source = "worldclim", bioclim = "bio14")
# bio15 <- getpastclimate(source = "worldclim", bioclim = "bio15")
# bio16 <- getpastclimate(source = "worldclim", bioclim = "bio16")
# bio17 <- getpastclimate(source = "worldclim", bioclim = "bio17")
# bio18 <- getpastclimate(source = "worldclim", bioclim = "bio18")
# bio19 <- getpastclimate(source = "worldclim", bioclim = "bio19")



######################## turn name-matched data.tables into SF ###################

trees4f_sf <- trees4f_db_selection %>% 
  sf::st_as_sf(coords = c("x", "y"), crs = 3035) %>% 
  sf::st_transform(crs = 4326) %>% 
  mutate(db = "trees4f")

open_trees_sf <- open_trees_db_selection %>% 
  filter(!is.na(x) & !is.na(y)) %>% 
  st_as_sf(coords = c("y", "x"), crs = 4326) %>% 
  mutate(db = "cadastres")

try_trees_sf <- try_trees_selection %>% 
  filter(!is.na(tree_georef_1_std_value) & !is.na(obs_data_std_value)) %>% 
  st_as_sf(coords = c("obs_data_std_value", "tree_georef_1_std_value"), crs = 4326) %>% 
  mutate(db = "try")

gbif_trees_sf <- gbif_trees %>% 
  dplyr::select(taxonkey, x = decimallatitude, y = decimallongitude) %>% 
  left_join(dplyr::select(tree_master_list, master_list_name = name, gbif_taxo_id), by = c("taxonkey" = "gbif_taxo_id")) %>% 
  filter(!is.na(x) & !is.na(y) & !is.na(master_list_name)) %>% 
  st_as_sf(coords = c("y", "x"), crs = 4326) %>% 
  # this will only keep observation inside Europe, i.e. the bounding box of the copernicus raster
  #sf::st_crop(st_bbox(bio01)) %>% 
  mutate(db = "gbif")

print("got all dbs and turned them into sf")
rm(gbif_trees, trees4f_db_selection, open_trees_db_selection, try_trees_selection)
######################## bind all three sources into one ####################################

tree_dbs <- rbind(
  as.data.table(trees4f_sf)[, .(master_list_name, db, geometry)],
  as.data.table(open_trees_sf)[, .(master_list_name, db, geometry)],
  as.data.table(try_trees_sf)[, .(master_list_name, db, geometry)],
  as.data.table(gbif_trees_sf)[, .(master_list_name, db, geometry)]
)

rm(gbif_trees_sf, open_trees_sf, try_trees_sf, trees4f_sf)

######################### The heart of it all: getting bioclimatic vars for each tree ##########
# ATTENTION with namespaces here. stringdist and raster both have an extract function. took me only an hour to figure out. 

print(paste0("starting extraction from rasters for ", nrow(tree_dbs), " tree occurrences"))

tree_dbs <- tree_dbs %>% 
  st_as_sf(crs = 4326) %>% 
  mutate(bio01_copernicus_1979_2018 = raster::extract(bio01_copernicus, .)) %>% 
  mutate(bio12_copernicus_1979_2018 = raster::extract(bio12_copernicus, .)) %>% 
  mutate(bio01_chelsa_1981_2010 = raster::extract(bio01_chelsa, .)) %>% 
  mutate(bio12_chelsa_1981_2010 = raster::extract(bio12_chelsa, .)) %>% 
  mutate(bio01_worldclim_1970_2000 = raster::extract(bio01_worldclim, .)) %>% 
  mutate(bio12_worldclim_1970_2000 = raster::extract(bio12_worldclim, .)) 


tree_dbs <- tree_dbs %>% 
  st_drop_geometry()
################################ write it all to sqlite #################################

data.table::fwrite(x = tree_dbs, file = "2_Data/1_output/tree_db.csv")

############# somehow sqlite doesnt write a table into DB###################
# if(!exists("con")){
#   con <- dbConnect(RSQLite::SQLite("2_Data/1_output/tree_db.sqlite"))
# }
# print("saving all that jazz into sqlite DB")
# RSQLite::dbWriteTable(conn = con,  name = "tree_occurrence", value = tree_dbs, 
#                       dplyr::select(tree_dbs, master_list_name, db, geometry, bio01_worldclim_1970_2000, bio12_worldclim_1970_2000,
#                                     bio01_chelsa_1981_2010, bio12_chelsa_1981_2010, 
#                                     bio01_copernicus_1979_2018, bio12_copernicus_1979_2018
#                       ), overwrite = TRUE)