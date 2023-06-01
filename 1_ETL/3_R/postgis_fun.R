# https://www.r-bloggers.com/2019/04/interact-with-postgis-from-r/
# followed this tutorial, just changed colors and the old postgis image from mdillon/postgis to postgis/postgis


if(!require(librarian)) install.packages("librarian")
library(librarian)
librarian::shelf(DBI,RPostgres,sf,dplyr,dbplyr,rnaturalearth,ggplot2)


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

pgWriteRast(con_raster,
            name = "copernicus", raster = future, overwrite = TRUE
)
# query raster values 
# https://postgis.net/docs/RT_ST_Value.html

