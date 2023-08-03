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
  
  rm(gbif_trees_sf, open_trees_sf, try_trees_sf, trees4f_sf, try_species)

  
  ######################### The heart of it all: getting bioclimatic vars for each tree ##########
  # ATTENTION with namespaces here. stringdist and raster both have an extract function. took me only an hour to figure out. 
  
  cat(paste0("Starting extraction for ", nrow(tree_dbs), " tree occurrences"))
  
  
  bio_vars <- c("bio01", "bio02", "bio03", "bio04", "bio05", "bio06", "bio07", "bio08", 
                "bio09", "bio10", "bio11", "bio12", "bio13", "bio14", "bio15", "bio16", "bio17", "bio18", "bio19")
  
  soil_vars <- c("STU_EU_DEPTH_ROOTS","STU_EU_T_CLAY","STU_EU_S_CLAY","STU_EU_T_SAND","STU_EU_S_SAND","STU_EU_T_SILT","STU_EU_S_SILT",
                 "STU_EU_T_OC","STU_EU_S_OC","STU_EU_T_BD","STU_EU_S_BD","STU_EU_T_GRAVEL","STU_EU_S_GRAVEL",
                 "SMU_EU_T_TAWC","SMU_EU_S_TAWC","STU_EU_T_TAWC", "STU_EU_S_TAWC")
  
  tree_dbs <- tree_dbs %>% 
    st_as_sf(crs = 4326)
  
  for (i in 1:length(bio_vars)) {
    tree_dbs <- tree_dbs %>% 
      mutate(terra::extract(getpastclimate(source = "copernicus", bioclim = bio_vars[i]), ., ID = F)) %>% 
      mutate(across(.cols = starts_with(c("BIO", "STU", "SMU")), ~ round(.x, digits = 2), .names = "{.col}")) 
    print(paste0("Finished extraction of ", bio_vars[i]))
  }
  for (i in 1:length(soil_vars)) {
    tree_dbs <- tree_dbs %>% 
      mutate(terra::extract(getsoilproperties(variable = soil_vars[i]), ., ID = F)) %>% 
      mutate(across(.cols = starts_with(c("BIO", "STU", "SMU")), ~ round(.x, digits = 2), .names = "{.col}")) 
    print(paste0("Finished extraction of ", soil_vars[i]))
  }
  
  
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