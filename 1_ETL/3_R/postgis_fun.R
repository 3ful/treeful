# https://www.r-bloggers.com/2019/04/interact-with-postgis-from-r/
# followed this tutorial, just changed colors and the old postgis image from mdillon/postgis to postgis/postgis


if(!require(librarian)) install.packages("librarian")
library(librarian)
librarian::shelf(DBI,RPostgres,sf,dplyr,dbplyr,rnaturalearth,ggplot2)


docker_cmd <- "run --detach --name some-postgis --publish 5432:5432 --env POSTGRES_PASSWORD=mysecretpassword -d postgis/postgis"
system2("docker", docker_cmd, stdout = TRUE, stderr = TRUE)


con <- DBI::dbConnect(RPostgres::Postgres(), 
                 dbname = "postgres",
                 host= "localhost", 
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

