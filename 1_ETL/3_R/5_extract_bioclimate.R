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
  
  ####### Soil data Prep for ESDAC rasters
  esdac_crs <- 'PROJCS["ETRS_1989_LAEA",
    GEOGCS["GCS_ETRS_1989",
        DATUM["D_ETRS_1989",
            SPHEROID["GRS_1980",6378137.0,298.257222101]],
        PRIMEM["Greenwich",0.0],
        UNIT["Degree",0.0174532925199433]],
    PROJECTION["Lambert_Azimuthal_Equal_Area"],
    PARAMETER["False_Easting",4321000.0],
    PARAMETER["False_Northing",3210000.0],
    PARAMETER["Central_Meridian",10.0],
    PARAMETER["Latitude_Of_Origin",52.0],
    UNIT["Meter",1.0]]'
  
  
  ######################### The heart of it all: getting bioclimatic vars for each tree ##########
  # ATTENTION with namespaces here. stringdist and raster both have an extract function. took me only an hour to figure out. 

  print(paste0("starting extraction from rasters for ", nrow(tree_dbs), " tree occurrences"))
  
  tree_dbs <- tree_dbs %>% 
    st_as_sf(crs = 4326) %>% 
    mutate(bio01_copernicus_1979_2018 = terra::extract(getpastclimate(source = "copernicus", bioclim = "bio01"), ., ID = F)[,1]) %>% 
    pipe_message("gotten BIO01 from Copernicus/n") %>%
    mutate(bio02_copernicus_1979_2018 = terra::extract(getpastclimate(source = "copernicus", bioclim = "bio02"), ., ID = F)[,1]) %>% 
    mutate(bio03_copernicus_1979_2018 = terra::extract(getpastclimate(source = "copernicus", bioclim = "bio03"), ., ID = F)[,1]) %>% 
    mutate(bio04_copernicus_1979_2018 = terra::extract(getpastclimate(source = "copernicus", bioclim = "bio04"), ., ID = F)[,1]) %>% 
    mutate(bio05_copernicus_1979_2018 = terra::extract(getpastclimate(source = "copernicus", bioclim = "bio05"), ., ID = F)[,1]) %>% 
    mutate(bio06_copernicus_1979_2018 = terra::extract(getpastclimate(source = "copernicus", bioclim = "bio06"), ., ID = F)[,1]) %>% 
    mutate(bio07_copernicus_1979_2018 = terra::extract(getpastclimate(source = "copernicus", bioclim = "bio07"), ., ID = F)[,1]) %>% 
    mutate(bio08_copernicus_1979_2018 = terra::extract(getpastclimate(source = "copernicus", bioclim = "bio08"), ., ID = F)[,1]) %>% 
    mutate(bio09_copernicus_1979_2018 = terra::extract(getpastclimate(source = "copernicus", bioclim = "bio09"), ., ID = F)[,1]) %>% 
    pipe_message("Finished BIO09") %>%
    mutate(bio10_copernicus_1979_2018 = terra::extract(getpastclimate(source = "copernicus", bioclim = "bio10"), ., ID = F)[,1]) %>% 
    mutate(bio11_copernicus_1979_2018 = terra::extract(getpastclimate(source = "copernicus", bioclim = "bio11"), ., ID = F)[,1]) %>% 
    mutate(bio12_copernicus_1979_2018 = terra::extract(getpastclimate(source = "copernicus", bioclim = "bio12"), ., ID = F)[,1]) %>% 
    mutate(bio13_copernicus_1979_2018 = terra::extract(getpastclimate(source = "copernicus", bioclim = "bio13"), ., ID = F)[,1]) %>% 
    mutate(bio14_copernicus_1979_2018 = terra::extract(getpastclimate(source = "copernicus", bioclim = "bio14"), ., ID = F)[,1]) %>% 
    mutate(bio15_copernicus_1979_2018 = terra::extract(getpastclimate(source = "copernicus", bioclim = "bio15"), ., ID = F)[,1]) %>% 
    mutate(bio16_copernicus_1979_2018 = terra::extract(getpastclimate(source = "copernicus", bioclim = "bio16"), ., ID = F)[,1]) %>% 
    mutate(bio17_copernicus_1979_2018 = terra::extract(getpastclimate(source = "copernicus", bioclim = "bio17"), ., ID = F)[,1]) %>% 
    mutate(bio18_copernicus_1979_2018 = terra::extract(getpastclimate(source = "copernicus", bioclim = "bio18"), ., ID = F)[,1]) %>% 
    mutate(bio19_copernicus_1979_2018 = terra::extract(getpastclimate(source = "copernicus", bioclim = "bio19"), ., ID = F)[,1]) %>% 
    pipe_message("Finished BIO19") %>%
    mutate(soil_depth_roots = terra::extract(getsoilproperties("STU_EU_DEPTH_ROOTS"), ., ID = F)[,1]) %>% 
    pipe_message("Root depth done") %>%
    mutate(soil_clay_topsoil = terra::extract(getsoilproperties("STU_EU_T_CLAY"), ., ID = F)[,1]) %>% 
    mutate(soil_clay_subsoil = terra::extract(getsoilproperties("STU_EU_S_CLAY"), ., ID = F)[,1]) %>% 
    pipe_message("Clay extraction done") %>%
    mutate(soil_sand_topsoil = terra::extract(getsoilproperties("STU_EU_T_SAND"), ., ID = F)[,1]) %>% 
    mutate(soil_sand_subsoil = terra::extract(getsoilproperties("STU_EU_S_SAND"), ., ID = F)[,1]) %>% 
    pipe_message("Sand extraction done") %>%
    mutate(soil_silt_topsoil = terra::extract(getsoilproperties("STU_EU_T_SILT"), ., ID = F)[,1]) %>% 
    mutate(soil_silt_subsoil = terra::extract(getsoilproperties("STU_EU_S_SILT"), ., ID = F)[,1]) %>% 
    mutate(soil_organic_carbon_topsoil = terra::extract(getsoilproperties("STU_EU_T_OC"), ., ID = F)[,1]) %>% 
    mutate(soil_organic_carbon_subsoil = terra::extract(getsoilproperties("STU_EU_S_OC"), ., ID = F)[,1]) %>% 
    mutate(soil_bulk_density_topsoil = terra::extract(getsoilproperties("STU_EU_T_BD"), ., ID = F)[,1]) %>% 
    mutate(soil_bulk_density_subsoil = terra::extract(getsoilproperties("STU_EU_S_BD"), ., ID = F)[,1]) %>% 
    mutate(soil_gravel_topsoil = terra::extract(getsoilproperties("STU_EU_T_GRAVEL"), ., ID = F)[,1]) %>% 
    mutate(soil_gravel_subsoil = terra::extract(getsoilproperties("STU_EU_S_GRAVEL"), ., ID = F)[,1]) %>% 
    pipe_message("Gravel extraction done") %>%
    mutate(soil_water_ptr_topsoil = terra::extract(getsoilproperties("SMU_EU_T_TAWC"), ., ID = F)[,1]) %>% 
    mutate(soil_water_ptr_subsoil = terra::extract(getsoilproperties("SMU_EU_S_TAWC"), ., ID = F)[,1]) %>% 
    mutate(soil_water_ptf_topsoil = terra::extract(getsoilproperties("STU_EU_T_TAWC"), ., ID = F)[,1]) %>% 
    mutate(soil_water_ptf_subsoil = terra::extract(getsoilproperties("STU_EU_S_TAWC"), ., ID = F)[,1]) %>% 
    mutate(across(.cols = starts_with(c("bio", "soil")), ~ round(.x, digits = 2), .names = "{.col}"))
  
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