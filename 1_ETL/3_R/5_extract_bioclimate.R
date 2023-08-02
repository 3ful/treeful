#################### LOad DBs, merge, turn into SF, extract bioclim #############################
pipe_message = function(.data, status) {message(status); .data}


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

  cat(paste0("Stacking bioclim and soil rasters together"))
  
  bioclim_stack <- c(
    getpastclimate(source = "copernicus", bioclim = "bio01"),
    getpastclimate(source = "copernicus", bioclim = "bio02"),
    getpastclimate(source = "copernicus", bioclim = "bio03"),
    getpastclimate(source = "copernicus", bioclim = "bio04"),
    getpastclimate(source = "copernicus", bioclim = "bio05"),
    getpastclimate(source = "copernicus", bioclim = "bio06"),
    getpastclimate(source = "copernicus", bioclim = "bio07"),
    getpastclimate(source = "copernicus", bioclim = "bio08"),
    getpastclimate(source = "copernicus", bioclim = "bio09"),
    getpastclimate(source = "copernicus", bioclim = "bio10"),
    getpastclimate(source = "copernicus", bioclim = "bio11"),
    getpastclimate(source = "copernicus", bioclim = "bio12"),
    getpastclimate(source = "copernicus", bioclim = "bio13"),
    getpastclimate(source = "copernicus", bioclim = "bio14"),
    getpastclimate(source = "copernicus", bioclim = "bio15"),
    getpastclimate(source = "copernicus", bioclim = "bio16"),
    getpastclimate(source = "copernicus", bioclim = "bio17"),
    getpastclimate(source = "copernicus", bioclim = "bio18"),
    getpastclimate(source = "copernicus", bioclim = "bio19")
  )
  
  soil_stack <- c(getsoilproperties("STU_EU_DEPTH_ROOTS"),
                  getsoilproperties("STU_EU_T_CLAY"),
                  getsoilproperties("STU_EU_S_CLAY"),
                  getsoilproperties("STU_EU_T_SAND"),
                  getsoilproperties("STU_EU_S_SAND"),
                  getsoilproperties("STU_EU_T_SILT"),
                  getsoilproperties("STU_EU_S_SILT"),
                  getsoilproperties("STU_EU_T_OC"),
                  getsoilproperties("STU_EU_S_OC"),
                  getsoilproperties("STU_EU_T_BD"),
                  getsoilproperties("STU_EU_S_BD"),
                  getsoilproperties("STU_EU_T_GRAVEL"),
                  getsoilproperties("STU_EU_S_GRAVEL"),
                  getsoilproperties("SMU_EU_T_TAWC"),
                  getsoilproperties("SMU_EU_S_TAWC"),
                  getsoilproperties("STU_EU_T_TAWC"),
                  getsoilproperties("STU_EU_S_TAWC"))
  
  cat(paste0("Starting extraction for ", nrow(tree_dbs), " tree occurrences"))
  
  tree_dbs <- tree_dbs %>% 
    st_as_sf(crs = 4326) %>% 
    mutate(terra::extract(soil_stack, ., ID = F)) %>% 
    mutate(terra::extract(bioclim_stack, ., ID = F)) %>% 
    mutate(across(.cols = starts_with(c("BIO", "STU", "SMU")), ~ round(.x, digits = 2), .names = "{.col}"))
  
  # tree_dbs <- tree_dbs %>% 
  #   st_drop_geometry()
  ################################ write it all to csv #################################
  data.table::fwrite(x = tree_dbs, file = "2_Data/1_output/tree_db.csv")
} else {
  cat("tree db exists, reading from disk/n")
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

##### EOF ####