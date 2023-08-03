print("large data transfer out starting. Writing all Rasters as rasterstack to Postgres")

con <- DBI::dbConnect(RPostgres::Postgres(), 
                      dbname = Sys.getenv("POSTGRES_DB"),
                      host= "192.168.178.148", 
                      port="5432",
                      user="postgres",
                      password=Sys.getenv("POSTGRES_PW"))
print("starting with reading Copernicus Future")
future <- raster::stack(raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio01")),
                        raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio02")),
                        raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio03")),
                        raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio04")),
                        raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio05")),
                        raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio06")),
                        raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio07")),
                        raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio08")),
                        raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio09")),
                        raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio10")),
                        raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio11")),
                        raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio12")),
                        raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio13")),
                        raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio14")),
                        raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio15")),
                        raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio16")),
                        raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio17")),
                        raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio18")),
                        raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio19"))
                        )

print("Reading in Copernicus past raster")
past <- raster::stack(raster::raster(getpastclimate(source = "copernicus", bioclim = "bio01")),
                        raster::raster(getpastclimate(source = "copernicus", bioclim = "bio02")),
                        raster::raster(getpastclimate(source = "copernicus", bioclim = "bio03")),
                        raster::raster(getpastclimate(source = "copernicus", bioclim = "bio04")),
                        raster::raster(getpastclimate(source = "copernicus", bioclim = "bio05")),
                        raster::raster(getpastclimate(source = "copernicus", bioclim = "bio06")),
                        raster::raster(getpastclimate(source = "copernicus", bioclim = "bio07")),
                        raster::raster(getpastclimate(source = "copernicus", bioclim = "bio08")),
                        raster::raster(getpastclimate(source = "copernicus", bioclim = "bio09")),
                        raster::raster(getpastclimate(source = "copernicus", bioclim = "bio10")),
                        raster::raster(getpastclimate(source = "copernicus", bioclim = "bio11")),
                        raster::raster(getpastclimate(source = "copernicus", bioclim = "bio12")),
                        raster::raster(getpastclimate(source = "copernicus", bioclim = "bio13")),
                        raster::raster(getpastclimate(source = "copernicus", bioclim = "bio14")),
                        raster::raster(getpastclimate(source = "copernicus", bioclim = "bio15")),
                        raster::raster(getpastclimate(source = "copernicus", bioclim = "bio16")),
                        raster::raster(getpastclimate(source = "copernicus", bioclim = "bio17")),
                        raster::raster(getpastclimate(source = "copernicus", bioclim = "bio18")),
                        raster::raster(getpastclimate(source = "copernicus", bioclim = "bio19"))
)
print("Reading in Soil Rasters")
soil <- raster::stack(raster::raster(getsoilproperties("STU_EU_DEPTH_ROOTS")),
                  raster::raster(getsoilproperties("STU_EU_T_CLAY")),
                  raster::raster(getsoilproperties("STU_EU_S_CLAY")),
                  raster::raster(getsoilproperties("STU_EU_T_SAND")),
                  raster::raster(getsoilproperties("STU_EU_S_SAND")),
                  raster::raster(getsoilproperties("STU_EU_T_SILT")),
                  raster::raster(getsoilproperties("STU_EU_S_SILT")),
                  raster::raster(getsoilproperties("STU_EU_T_OC")),
                  raster::raster(getsoilproperties("STU_EU_S_OC")),
                  raster::raster(getsoilproperties("STU_EU_T_BD")),
                  raster::raster(getsoilproperties("STU_EU_S_BD")),
                  raster::raster(getsoilproperties("STU_EU_T_GRAVEL")),
                  raster::raster(getsoilproperties("STU_EU_S_GRAVEL")),
                  raster::raster(getsoilproperties("SMU_EU_T_TAWC")),
                  raster::raster(getsoilproperties("SMU_EU_S_TAWC")),
                  raster::raster(getsoilproperties("STU_EU_T_TAWC")),
                  raster::raster(getsoilproperties("STU_EU_S_TAWC"))
          )

# 
# pastbio01 <- getpastclimate(source = "copernicus", bioclim = "bio01")
# 
# 
# pastbio12 <- getpastclimate(source = "copernicus", bioclim = "bio12")
# crs(pastbio12) <- "+proj=longlat +datum=WGS84 +no_defs +type=crs"
# # we set this proj here and it seems to stick to R raster object. 
# # when writing into postgis, there SRID appears to be 3395

print("Writing Copernicus Past to DB")
rpostgis::pgWriteRast(con,
            name = "past", raster = past, overwrite = TRUE
)
print("Writing Copernicus Future to DB")
rpostgis::pgWriteRast(con,
            name = "future", raster = future, overwrite = TRUE
)
print("Writing Soil to DB")
rpostgis::pgWriteRast(con,
                      name = "soil", raster = soil, overwrite = TRUE
)

DBI::dbDisconnect(conn = con)