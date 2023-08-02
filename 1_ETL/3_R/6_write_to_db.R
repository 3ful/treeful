
con <- DBI::dbConnect(RPostgres::Postgres(), 
                      dbname = Sys.getenv("POSTGRES_DB"),
                      host= "192.168.178.148", 
                      port="5432",
                      user="postgres",
                      password=Sys.getenv("POSTGRES_PW"))

write_to_db <- function() {
  
}



future <- raster::stack(getfutureclimate(source = "copernicus", bioclim = "bio01"),
                        getfutureclimate(source = "copernicus", bioclim = "bio02"),
                        getfutureclimate(source = "copernicus", bioclim = "bio03"),
                        getfutureclimate(source = "copernicus", bioclim = "bio04"),
                        getfutureclimate(source = "copernicus", bioclim = "bio05"),
                        getfutureclimate(source = "copernicus", bioclim = "bio06"),
                        getfutureclimate(source = "copernicus", bioclim = "bio07"),
                        getfutureclimate(source = "copernicus", bioclim = "bio08"),
                        getfutureclimate(source = "copernicus", bioclim = "bio09"),
                        getfutureclimate(source = "copernicus", bioclim = "bio10"),
                        getfutureclimate(source = "copernicus", bioclim = "bio11"),
                        getfutureclimate(source = "copernicus", bioclim = "bio12"),
                        getfutureclimate(source = "copernicus", bioclim = "bio13"),
                        getfutureclimate(source = "copernicus", bioclim = "bio14"),
                        getfutureclimate(source = "copernicus", bioclim = "bio15"),
                        getfutureclimate(source = "copernicus", bioclim = "bio16"),
                        getfutureclimate(source = "copernicus", bioclim = "bio17"),
                        getfutureclimate(source = "copernicus", bioclim = "bio18"),
                        getfutureclimate(source = "copernicus", bioclim = "bio19")
                        )


past <- raster::stack(getpastclimate(source = "copernicus", bioclim = "bio01"),
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
# 
# pastbio01 <- getpastclimate(source = "copernicus", bioclim = "bio01")
# 
# 
# pastbio12 <- getpastclimate(source = "copernicus", bioclim = "bio12")
# crs(pastbio12) <- "+proj=longlat +datum=WGS84 +no_defs +type=crs"
# # we set this proj here and it seems to stick to R raster object. 
# # when writing into postgis, there SRID appears to be 3395


rpostgis::pgWriteRast(con,
            name = "past", raster = past, overwrite = TRUE
)
rpostgis::pgWriteRast(con,
            name = "future", raster = future, overwrite = TRUE
)


DBI::dbDisconnect(conn = con)