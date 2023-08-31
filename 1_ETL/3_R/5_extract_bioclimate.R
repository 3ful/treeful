#################### LOad DBs, merge, turn into SF, extract bioclim #############################

if (!file.exists("2_Data/1_output/tree_db.csv")) {
  
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
    left_join(dplyr::select(tree_master_list, master_list_name = latin_name, gbif_taxo_id), by = c("taxonkey" = "gbif_taxo_id")) %>% 
    filter(!is.na(x) & !is.na(y) & !is.na(master_list_name)) %>% 
    st_as_sf(coords = c("y", "x"), crs = 4326) %>% 
    mutate(db = "gbif")
  
  sendstatus("got all dbs and turned them into sf")
  rm(gbif_trees, trees4f_db_selection, open_trees_db_selection, try_trees_selection)
  ######################## bind all three sources into one ####################################
  
  tree_dbs <- rbind(
    as.data.table(trees4f_sf)[, .(master_list_name, db, geometry)],
    as.data.table(open_trees_sf)[, .(master_list_name, db, geometry)],
    as.data.table(try_trees_sf)[, .(master_list_name, db, geometry)],
    as.data.table(gbif_trees_sf)[, .(master_list_name, db, geometry)]
  )
  
  rm(gbif_trees_sf, open_trees_sf, try_trees_sf, trees4f_sf, try_species)
  gc()
  
  ######################### The heart of it all: getting bioclimatic vars for each tree ##########
  sendstatus(paste0("Cutting down tree db to species with n>1500, currently at ", nrow(tree_dbs)))
  
  tree_count <- tree_dbs %>% 
    group_by(master_list_name) %>% 
    summarise(n=n()) %>% 
    filter(n>1500)
  
  tree_dbs <- tree_dbs %>% 
    filter(master_list_name %in% tree_count$master_list_name)
  gc()
  
  sendstatus(paste0("Cut small species occurrences. Starting extraction for ", nrow(tree_dbs), " tree occurrences"))
  
  tree_dbs <- tree_dbs %>% 
    st_as_sf(crs = 4326)
  
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
  sendstatus("read and stacked bioclim rasters. starting bioclim extraction")
  
  tree_dbs <- tree_dbs %>% 
    mutate(terra::extract(bioclim_stack, ., ID = F)) 
  
  rm(bioclim_stack)
  gc()
  
  ##### soil data extraction begin
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
  sendstatus("read and stacked soil rasters. starting soil extraction")
  tree_dbs <- tree_dbs %>% 
    mutate(terra::extract(soil_stack, ., ID = F)) %>% 
    mutate(across(.cols = starts_with(c("BIO", "STU", "SMU")), ~ round(.x, digits = 2), .names = "{.col}"))
  
  rm(soil_stack)
  gc()
  
  # tree_dbs <- tree_dbs %>% 
  #   st_drop_geometry()
  ################################ write it all to csv #################################
  sendstatus("saving DB to disk")
  data.table::fwrite(x = tree_dbs, file = "2_Data/1_output/tree_db.csv")
} else {
  sendstatus("tree db exists, reading from disk/n")
  tree_dbs <- fread("2_Data/1_output/tree_db.csv")
}

con <- backend_con()

if (!RPostgres::dbExistsTable(conn = con, name = "tree_dbs")) {
  # writing trees to postgres DB
  sendstatus("writing tree db to postgres")
  con <- backend_con()
  
  sf::st_write(tree_dbs, dsn = con, table = "tree_dbs",
               append = FALSE)
}


tree_db_sample_size <- group_by(tree_dbs, master_list_name) %>% 
  summarise(n=n())

tree_master_list <- fread("2_Data/1_output/eu_native_trees_master.csv") %>% 
  left_join(tree_db_sample_size, by = c("latin_name" = "master_list_name")) %>% 
  filter(n>1500)

sendstatus(paste0("Had ", nrow(tree_db_sample_size), " species, now down to ", nrow(tree_master_list)))

fwrite(tree_master_list, "2_Data/1_output/eu_native_trees_master.csv")

rm(tree_db_sample_size, tree_master_list)
gc()

DBI::dbDisconnect(conn = con)

##### EOF ####