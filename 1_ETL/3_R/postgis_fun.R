# https://www.r-bloggers.com/2019/04/interact-with-postgis-from-r/
# followed this tutorial, just changed colors and the old postgis image from mdillon/postgis to postgis/postgis


if(!require(librarian)) install.packages("librarian")
library(librarian)
librarian::shelf(DBI,RPostgres,sf,dplyr,dbplyr,rnaturalearth,ggplot2, raster)


docker_cmd <- "run --detach --name some-postgis --publish 5432:5432 --env POSTGRES_PASSWORD=mysecretpassword -d postgis/postgis"
system2("docker", docker_cmd, stdout = TRUE, stderr = TRUE)


con <- DBI::dbConnect(RPostgres::Postgres(), 
                 dbname = "postgres",
                 host= "192.168.178.110", 
                 port="5432",
                 user="postgres",
                 password="mysecretpassword")

ne_world <- rnaturalearth::ne_countries(scale = 50, returnclass = "sf")
# Choose one available to you
world_map_crs <- "+proj=eqearth +wktext"

# Use your custom colours
ne_world %>% 
  st_transform(world_map_crs) %>% 
  ggplot() +
  geom_sf(fill = "brown", colour = "red") +
  theme(panel.background = element_rect(fill = "blue"))


sf::st_write(ne_world, dsn = con, layer = "ne_world",
         append = FALSE)




world_sf <- sf::st_read(con, layer = "ne_world")
world_sf %>% 
  st_transform(world_map_crs) %>% 
  ggplot() +
  geom_sf(fill = "brown", colour = "red") +
  theme(panel.background = element_rect(fill = "blue"))


query <- paste(
  'SELECT "name", "name_long", "geometry"',
  'FROM "ne_world"',
  'WHERE ("continent" = \'Africa\');'
)
africa_sf <- st_read(con, query = query)


africa_sf %>% 
  st_transform(world_map_crs) %>% 
  ggplot() +
  geom_sf(fill = "brown", colour = "red") +
  theme(panel.background = element_rect(fill = "blue"))


# Disconnect database
DBI::dbDisconnect(con)
# Stop Docker container
# system2("docker", "stop some-postgis")
# system2("docker", "rm --force some-postgis")
# # Verify docker
# system2("docker", "ps -a")



sf::st_write(tree_dbs, dsn = con, table = "trees",
             append = FALSE)


test_trees <- sf::st_read(con, layer = "obj")

library(rpostgis)
# you need to enable raster support on the postgis container as per 
# https://sheeyphone.github.io/2023/02/26/p20230226/
# execute this query:
# CREATE EXTENSION postgis_raster;
# SET postgis.gdal_enabled_drivers = 'ENABLE_ALL';
# SELECT name, default_version,installed_version
# FROM pg_available_extensions WHERE name LIKE 'postgis%' or name LIKE 'address%';

# run a pgadmin container to see if all ends up in DB
# docker run -p 80:80     -e 'PGADMIN_DEFAULT_EMAIL=user@domain.com'     -e 'PGADMIN_DEFAULT_PASSWORD=ortant: set TTN mapper port filter to '4SuperSecret'     -d dpage/pgadmin4



con_raster <- RPostgreSQL::dbConnect("PostgreSQL",
                                     host = "192.168.178.110", dbname = "postgres",
                                     user = "postgres", password = "mysecretpassword", port = 5432
)

# check if the database has PostGIS
pgPostGIS(con_raster)
## [1] TRUE

# load future raster
source("3_R/3_fn_get_climate_rasters.R")
future <- getfutureclimate(source = "copernicus")

pastbio01 <- getpastclimate(source = "copernicus", bioclim = "bio01")
crs(pastbio01) <- "+proj=longlat +datum=WGS84 +no_defs +type=crs"
# we set this proj here and it seems to stick to R raster object. 
# when writing into postgis, there SRID appears to be 3395


pgWriteRast(con_raster,
            name = "copernicus", raster = pastbio01, overwrite = TRUE
)
# probably a functionaing query finally
# SELECT g.pt_geom, ST_Value(r.rast, g.pt_geom) AS elev
# FROM public.copernicus AS r
# INNER JOIN
# (SELECT ST_Transform(ST_SetSRID(ST_MakePoint(11,51), 4326),4326) As pt_geom) AS g
# ON r.rast && g.pt_geom;
# inspired from here https://postgis.net/workshops/postgis-intro/rasters.html

# here is how we will query for user locations.
RPostgreSQL::dbGetQuery(con_raster, "SELECT g.pt_geom, ST_Value(r.rast, g.pt_geom) AS biovar
FROM public.pastbio01 AS r
INNER JOIN
(SELECT ST_Transform(ST_SetSRID(ST_MakePoint(11,51), 4326),4326) As pt_geom) AS g
ON r.rast && g.pt_geom;")


# query raster values 
# https://postgis.net/docs/RT_ST_Value.html

esdac_crs <- "+proj=laea +lat_0=52 +lon_0=10 +x_0=4321000 +y_0=3210000 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs +type=crs"

roots <- stars::read_stars("2_Data/0_raw_data/soil/STU_EU_DEPTH_ROOTS.rst") %>%  st_transform(crs = 3035)

beginCluster()
roots <- raster::projectRaster(raster::raster("2_Data/0_raw_data/soil/STU_EU_DEPTH_ROOTS.rst", crs = esdac_crs), crs = "+proj=longlat +datum=WGS84 +no_defs")
endCluster()
plot(roots)
stars::
stars::st_transform_proj(roots, crs = st_crs(stars::st_as_stars(getpastclimate(source = "copernicus", bioclim = "bio01"))))
raster::extract(raster::raster("2_Data/0_raw_data/soil/STU_EU_DEPTH_ROOTS.rst", crs = esdac_crs), filter(st_as_sf(tree_dbs, crs = 4326), is.na(st_dimension(.)) == FALSE))

tree_dbs_laea <- tree_dbs %>% 
  st_as_sf(crs = 4326) %>% 
  st_transform(crs = esdac_crs)
  
roots <- terra::rast("2_Data/0_raw_data/soil/STU_EU_DEPTH_ROOTS.rst")
roots <- terra::project(roots)
terra::crs(roots) <- esdac_crs

roots <- terra::project(roots, "epsg:4326")
# trying to find a more memory efficient solution to raster extract. exactextractr sounds promising, velox too but seems unmaintained. 

exact_extract(roots, slice(st_as_sf(tree_dbs, crs  = 4326) , 1:100), 'mean')

getsoilproperties <- function(variable = "STU_EU_DEPTH_ROOTS") {
  esdac_crs <- "+proj=laea +lat_0=52 +lon_0=10 +x_0=4321000 +y_0=3210000 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs +type=crs"
  soil_layer <- terra::rast(paste0("2_Data/0_raw_data/soil/", variable, ".rst"))
  terra::crs(soil_layer) <- esdac_crs
  soil_layer <- terra::project(soil_layer, "epsg:4326")  
}


tree_dbs <- tree_dbs %>% 
  st_as_sf(crs = 4326) %>% 
  mutate(bio01_copernicus_1979_2018 = terra::extract(getpastclimate(source = "copernicus", bioclim = "bio01"), ., ID = F)[,1]) %>% 
  mutate(soil_depth_roots = terra::extract(getsoilproperties("STU_EU_DEPTH_ROOTS"), ., ID = F)[,1]) 

tree_dbs_exact <- tree_dbs %>% 
  st_as_sf(crs = 4326) %>% 
  slice(1:1000000) %>% 
  mutate(root = exact_extract(getsoilproperties("STU_EU_DEPTH_ROOTS"), ., 'sum'))

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



exact_extract(soil_stack, slice(st_as_sf(tree_dbs, crs = 4326), 1:100))

bio_raster <- stars::read_stars(paste0("2_Data/0_raw_data/past/", bio_path, "_era5-to-1km_1979-2018-mean_v1.0.nc"))
soil_stack <- stars::read_stars(c("2_Data/0_raw_data/soil/STU_EU_DEPTH_ROOTS.rst", 
                                "2_Data/0_raw_data/soil/STU_EU_S_CLAY.rst", 
                                "2_Data/0_raw_data/soil/STU_EU_S_GRAVEL.rst"), crs = 3035)
st_crs(soil_stack) <- 3035
soil_stack <- st_transform(soil_stack, crs = 4326)
soil_stack <- st_warp(soil_stack, crs = 4326)

stars::st_extract(bio_raster, slice(st_as_sf(tree_dbs, crs = 4326), 1:100))

# last try at making this extraction efficient: for-looping it all

bio_vars <- c("bio01", "bio02", "bio03", "bio04", "bio05", "bio06", "bio07", "bio08", 
              "bio09", "bio10", "bio11", "bio12", "bio13", "bio14", "bio15", "bio16", "bio17", "bio18", "bio19")

soil_vars <- c("STU_EU_DEPTH_ROOTS","STU_EU_T_CLAY","STU_EU_S_CLAY","STU_EU_T_SAND","STU_EU_S_SAND","STU_EU_T_SILT","STU_EU_S_SILT",
               "STU_EU_T_OC","STU_EU_S_OC","STU_EU_T_BD","STU_EU_S_BD","STU_EU_T_GRAVEL","STU_EU_S_GRAVEL",
               "SMU_EU_T_TAWC","SMU_EU_S_TAWC","STU_EU_T_TAWC", "STU_EU_S_TAWC")

tree_dbs <- tree_dbs %>% 
  st_as_sf(crs = 4326)

for (i in 1:length(bio_vars)) {
  tree_dbs <- tree_dbs %>% 
    slice(1:100) %>% 
    mutate(terra::extract(getpastclimate(source = "copernicus", bioclim = bio_vars[i]), ., ID = F)) %>% 
    mutate(across(.cols = starts_with(c("BIO", "STU", "SMU")), ~ round(.x, digits = 2), .names = "{.col}")) 
    gc()
    print(aste0("Finished extraction of ", bio_vars[i]))
}
for (i in 1:length(soil_vars)) {
  tree_dbs <- tree_dbs %>% 
    slice(1:100) %>% 
    mutate(terra::extract(getsoilproperties(variable = soil_vars[i]), ., ID = F)) %>% 
    mutate(across(.cols = starts_with(c("BIO", "STU", "SMU")), ~ round(.x, digits = 2), .names = "{.col}")) 
  gc()
  print(aste0("Finished extraction of ", soil_vars[i]))
}


####### Cemetery of abandoned approaches for efficient raster extracion 
# stack it all together. too large for memory
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


tree_dbs <- tree_dbs %>% 
  st_as_sf(crs = 4326) %>% 
  mutate(terra::extract(soil_stack, ., ID = F)) %>% 
  mutate(terra::extract(bioclim_stack, ., ID = F)) %>% 
  mutate(across(.cols = starts_with(c("BIO", "STU", "SMU")), ~ round(.x, digits = 2), .names = "{.col}"))

###### the tidyverse way

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
  mutate(soil_depth_roots = raster::extract(getsoilproperties("STU_EU_DEPTH_ROOTS"), .)) %>% 
  mutate(soil_clay_topsoil = raster::extract(getsoilproperties("STU_EU_T_CLAY"), .)) %>% 
  mutate(soil_clay_subsoil = raster::extract(getsoilproperties("STU_EU_S_CLAY"), .)) %>% 
  mutate(soil_sand_topsoil = raster::extract(getsoilproperties("STU_EU_T_SAND"), .)) %>% 
  mutate(soil_sand_subsoil = raster::extract(getsoilproperties("STU_EU_S_SAND"), .)) %>% 
  mutate(soil_silt_topsoil = raster::extract(getsoilproperties("STU_EU_T_SILT"), .)) %>% 
  mutate(soil_silt_subsoil = raster::extract(getsoilproperties("STU_EU_S_SILT"), .)) %>% 
  mutate(soil_organic_carbon_topsoil = raster::extract(getsoilproperties("STU_EU_T_OC"), .)) %>% 
  mutate(soil_organic_carbon_subsoil = raster::extract(getsoilproperties("STU_EU_S_OC"), .)) %>% 
  mutate(soil_bulk_density_topsoil = raster::extract(getsoilproperties("STU_EU_T_BD"), .)) %>% 
  mutate(soil_bulk_density_subsoil = raster::extract(getsoilproperties("STU_EU_S_BD"), .)) %>% 
  mutate(soil_gravel_topsoil = raster::extract(getsoilproperties("STU_EU_T_GRAVEL"), .)) %>% 
  mutate(soil_gravel_subsoil = raster::extract(getsoilproperties("STU_EU_S_GRAVEL"), .)) %>% 
  mutate(soil_water_ptr_topsoil = raster::extract(getsoilproperties("SMU_EU_T_TAWC"), .)) %>% 
  mutate(soil_water_ptr_subsoil = raster::extract(getsoilproperties("SMU_EU_S_TAWC"), .)) %>% 
  mutate(soil_water_ptf_topsoil = raster::extract(getsoilproperties("STU_EU_T_TAWC"), .)) %>% 
  mutate(soil_water_ptf_subsoil = raster::extract(getsoilproperties("STU_EU_S_TAWC"), .)) %>% 
  mutate(across(.cols = starts_with(c("bio", "soil")), ~ round(.x, digits = 2), .names = "{.col}"))


##### to add to some processing part. reprojection of ESDAC files

for (i in 1:length(soil_vars)) {
  esdac_crs <- "+proj=laea +lat_0=52 +lon_0=10 +x_0=4321000 +y_0=3210000 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs +type=crs"
  soil_layer <- raster::raster(paste0("2_Data/0_raw_data/soil/", soil_vars[i], ".rst"))
  raster::crs(soil_layer) <- esdac_crs
  soil_layer <- terra::project(terra::rast(soil_layer), "epsg:4326")  
  terra::writeRaster(soil_layer, paste0("2_Data/0_raw_data/soil/", soil_vars[i], "_4326.tif"), overwrite = T)
  cat("wrote ", soil_vars[i], " to disk\n")
}
