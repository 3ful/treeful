
con <- DBI::dbConnect(RPostgres::Postgres(), 
                      dbname = Sys.getenv("POSTGRES_DB"),
                      host= "192.168.178.148", 
                      port="5432",
                      user="postgres",
                      password=Sys.getenv("POSTGRES_PW"))

future <- getfutureclimate(source = "copernicus")
crs(future) <- "+proj=longlat +datum=WGS84 +no_defs +type=crs"

pastbio01 <- getpastclimate(source = "copernicus", bioclim = "bio01")
crs(pastbio01) <- "+proj=longlat +datum=WGS84 +no_defs +type=crs"

pastbio12 <- getpastclimate(source = "copernicus", bioclim = "bio12")
crs(pastbio12) <- "+proj=longlat +datum=WGS84 +no_defs +type=crs"
# we set this proj here and it seems to stick to R raster object. 
# when writing into postgis, there SRID appears to be 3395


rpostgis::pgWriteRast(con,
            name = "pastbio01", raster = pastbio01, overwrite = TRUE
)

rpostgis::pgWriteRast(con,
            name = "pastbio12", raster = pastbio12, overwrite = TRUE
)
rpostgis::pgWriteRast(con,
            name = "future", raster = future, overwrite = TRUE
)


DBI::dbDisconnect(conn = con)