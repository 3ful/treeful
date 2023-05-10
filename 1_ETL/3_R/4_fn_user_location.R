#function to fetch bioclimatic indicators of past and future for specific lat lon in epsg 4326

get_user_climate <- function(lat = 51.28672, lon = 11.01653) {
  map_point <- st_as_sf(tibble(lat = lat, lon = lon), coords = c("lon", "lat"), crs = 4326)
  #get future at map location
  bio01_future <- raster::extract(future_raster$bio01, map_point)
  bio12_future <- raster::extract(future_raster$bio12, map_point)
  # get historic conditions
  bio01_hist <- raster::extract(bio01_copernicus, map_point)
  # bio02_hist <- raster::extract(bio02, map_point)
  # bio03_hist <- raster::extract(bio03, map_point)
  # bio04_hist <- raster::extract(bio04, map_point)
  # bio05_hist <- raster::extract(bio05, map_point)
  # bio06_hist <- raster::extract(bio06, map_point)
  # bio07_hist <- raster::extract(bio07, map_point)
  # bio08_hist <- raster::extract(bio08, map_point)
  # bio09_hist <- raster::extract(bio09, map_point)
  # bio10_hist <- raster::extract(bio10, map_point)
  # bio11_hist <- raster::extract(bio11, map_point)
  bio12_hist <- raster::extract(bio12_copernicus, map_point)
  # bio13_hist <- raster::extract(bio13, map_point)
  # bio14_hist <- raster::extract(bio14, map_point)
  # bio15_hist <- raster::extract(bio15, map_point)
  # bio16_hist <- raster::extract(bio16, map_point)
  # bio17_hist <- raster::extract(bio17, map_point)
  # bio18_hist <- raster::extract(bio18, map_point)
  # bio19_hist <- raster::extract(bio19, map_point)
  return(tibble(bio01_future, bio12_future, 
                bio01_hist, bio12_hist
                ))
  rm(bio01_future, bio12_future, 
     bio01_hist, bio12_hist)
  
}
