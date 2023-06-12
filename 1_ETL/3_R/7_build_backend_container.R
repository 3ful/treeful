# at this point we should have a table in some form with tree locations and their bioclim variables. 
# then we download raster files from CDS
# then we stick these rasters (after some conversion) into a postgis DB. 
# this file will be a Dockerfile calling R scripts. 

# docker stuff to spin postgis container, in ssame network and reachable by frontend and rstudio
# also with raster extensions enabled. 

## For dockerfile
# postgres container
# r container: rocker geospatial. download cds. stick into postgres

source("3_R/3_fn_get_climate_rasters.R")

pastbio01 <- getpastclimate(source = "copernicus", bioclim = "bio01")
pastbio12 <- getpastclimate(source = "copernicus", bioclim = "bio12")
futurebio01 <- getfutureclimate(source = "copernicus")$bio01
futurebio12 <- getfutureclimate(source = "copernicus")$bio12

crs(pastbio01) <- "+proj=longlat +datum=WGS84 +no_defs +type=crs"
crs(pastbio12) <- "+proj=longlat +datum=WGS84 +no_defs +type=crs"
crs(futurebio01) <- "+proj=longlat +datum=WGS84 +no_defs +type=crs"
crs(futurebio12) <- "+proj=longlat +datum=WGS84 +no_defs +type=crs"
# we set this proj here and it seems to stick to R raster object. 
# when writing into postgis, there SRID appears to be 3395
pgWriteRast(con_raster,
            name = "pastbio01", raster = pastbio01, overwrite = TRUE
)
pgWriteRast(con_raster,
            name = "pastbio12", raster = pastbio12, overwrite = TRUE
)
pgWriteRast(con_raster,
            name = "futurebio01", raster = futurebio01, overwrite = TRUE
)
pgWriteRast(con_raster,
            name = "futurebio12", raster = futurebio12, overwrite = TRUE
)
