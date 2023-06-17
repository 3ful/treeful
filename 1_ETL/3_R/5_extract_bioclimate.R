#################### LOad DBs, merge, turn into SF, extract bioclim #############################

if (!file.exists("2_Data/1_output/tree_db.csv")) {
  
  gbif_trees <- data.table::fread(file = "2_Data/1_output/gbif_eu_trees.csv")
  
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
    mutate(bio01_copernicus_1979_2018 = raster::extract(getpastclimate(source = "copernicus", bioclim = "bio01"), .)) %>% 
    mutate(bio02_copernicus_1979_2018 = raster::extract(getpastclimate(source = "copernicus", bioclim = "bio02"), .)) %>% 
    mutate(bio03_copernicus_1979_2018 = raster::extract(getpastclimate(source = "copernicus", bioclim = "bio03"), .)) %>% 
    mutate(bio04_copernicus_1979_2018 = raster::extract(getpastclimate(source = "copernicus", bioclim = "bio04"), .)) %>% 
    mutate(bio05_copernicus_1979_2018 = raster::extract(getpastclimate(source = "copernicus", bioclim = "bio05"), .)) %>% 
    mutate(bio06_copernicus_1979_2018 = raster::extract(getpastclimate(source = "copernicus", bioclim = "bio06"), .)) %>% 
    mutate(bio07_copernicus_1979_2018 = raster::extract(getpastclimate(source = "copernicus", bioclim = "bio07"), .)) %>% 
    mutate(bio08_copernicus_1979_2018 = raster::extract(getpastclimate(source = "copernicus", bioclim = "bio08"), .)) %>% 
    mutate(bio09_copernicus_1979_2018 = raster::extract(getpastclimate(source = "copernicus", bioclim = "bio09"), .)) %>% 
    mutate(bio10_copernicus_1979_2018 = raster::extract(getpastclimate(source = "copernicus", bioclim = "bio10"), .)) %>% 
    mutate(bio11_copernicus_1979_2018 = raster::extract(getpastclimate(source = "copernicus", bioclim = "bio11"), .)) %>% 
    mutate(bio12_copernicus_1979_2018 = raster::extract(getpastclimate(source = "copernicus", bioclim = "bio12"), .)) %>% 
    mutate(bio13_copernicus_1979_2018 = raster::extract(getpastclimate(source = "copernicus", bioclim = "bio13"), .)) %>% 
    mutate(bio14_copernicus_1979_2018 = raster::extract(getpastclimate(source = "copernicus", bioclim = "bio14"), .)) %>% 
    mutate(bio15_copernicus_1979_2018 = raster::extract(getpastclimate(source = "copernicus", bioclim = "bio15"), .)) %>% 
    mutate(bio16_copernicus_1979_2018 = raster::extract(getpastclimate(source = "copernicus", bioclim = "bio16"), .)) %>% 
    mutate(bio17_copernicus_1979_2018 = raster::extract(getpastclimate(source = "copernicus", bioclim = "bio17"), .)) %>% 
    mutate(bio18_copernicus_1979_2018 = raster::extract(getpastclimate(source = "copernicus", bioclim = "bio18"), .)) %>% 
    mutate(bio19_copernicus_1979_2018 = raster::extract(getpastclimate(source = "copernicus", bioclim = "bio19"), .)) %>% 
    mutate(across(.cols = starts_with("bio"), ~ round(.x, digits = 2), .names = "{.col}"))
  
  # tree_dbs <- tree_dbs %>% 
  #   st_drop_geometry()
  ################################ write it all to csv #################################
  data.table::fwrite(x = tree_dbs, file = "2_Data/1_output/tree_db.csv")
} else {
  cat("tree db exists, reading from disk")
  tree_dbs <- fread("2_Data/1_output/tree_db.csv")
}

# writing trees to postgres DB
cat("writing tree db to postgres")
con <- DBI::dbConnect(RPostgres::Postgres(), 
                      dbname = Sys.getenv("POSTGRES_DB"),
                      host= "192.168.178.148", 
                      port="5432",
                      user="postgres",
                      password=Sys.getenv("POSTGRES_PW"))
sf::st_write(tree_dbs, dsn = con, table = "trees",
             append = FALSE)
DBI::dbDisconnect(conn = con)


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