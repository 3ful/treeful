print("large data transfer out starting. Writing all Rasters as rasterstack to Postgres")

con <- backend_con()

# 
# pastbio01 <- getpastclimate(source = "copernicus", bioclim = "bio01")
# 
# 
# pastbio12 <- getpastclimate(source = "copernicus", bioclim = "bio12")
# crs(pastbio12) <- "+proj=longlat +datum=WGS84 +no_defs +type=crs"
# # we set this proj here and it seems to stick to R raster object. 
# # when writing into postgis, there SRID appears to be 3395

########################## Past Raster ############################
if (!RPostgres::dbExistsTable(conn = con, name = "past")) {
  sendstatus("Reading in Copernicus past raster")
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
  sendstatus("Writing Copernicus Past to DB")
  rpostgis::pgWriteRast(con,
                        name = "past", raster = past, overwrite = TRUE
  )
  rm(past)
  gc()
  } else {
    cat("Raster layers exist in Postgres. Skipping. ")
  }
  
########################## Future 2050 4.5 Raster ############################
if (!RPostgres::dbExistsTable(conn = con, name = "future_2050_4_5")) {
  sendstatus("starting with reading Copernicus Future 2050 4.5")
  future <- raster::stack(raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio01", experiment = "rcp45", future_date = "2050-01-01")),
                          raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio02", experiment = "rcp45", future_date = "2050-01-01")),
                          raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio03", experiment = "rcp45", future_date = "2050-01-01")),
                          raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio04", experiment = "rcp45", future_date = "2050-01-01")),
                          raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio05", experiment = "rcp45", future_date = "2050-01-01")),
                          raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio06", experiment = "rcp45", future_date = "2050-01-01")),
                          raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio07", experiment = "rcp45", future_date = "2050-01-01")),
                          raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio08", experiment = "rcp45", future_date = "2050-01-01")),
                          raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio09", experiment = "rcp45", future_date = "2050-01-01")),
                          raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio10", experiment = "rcp45", future_date = "2050-01-01")),
                          raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio11", experiment = "rcp45", future_date = "2050-01-01")),
                          raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio12", experiment = "rcp45", future_date = "2050-01-01")),
                          raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio13", experiment = "rcp45", future_date = "2050-01-01")),
                          raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio14", experiment = "rcp45", future_date = "2050-01-01")),
                          raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio15", experiment = "rcp45", future_date = "2050-01-01")),
                          raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio16", experiment = "rcp45", future_date = "2050-01-01")),
                          raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio17", experiment = "rcp45", future_date = "2050-01-01")),
                          raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio18", experiment = "rcp45", future_date = "2050-01-01")),
                          raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio19", experiment = "rcp45", future_date = "2050-01-01"))
  )
  
  sendstatus("Writing Copernicus Future 2050 4.5")
  rpostgis::pgWriteRast(con,
                        name = "future_2050_4_5", raster = future, overwrite = TRUE
  )
  rm(future)
  gc()
  } else {
    cat("Raster layers exist in Postgres. Skipping. ")
}
  
  
########################## Future 2050 8.5 Raster ############################
if (!RPostgres::dbExistsTable(conn = con, name = "future_2050_8_5")) {
  sendstatus("starting with reading Copernicus Future 2050 8.5")
  future <- raster::stack(raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio01", experiment = "rcp85", future_date = "2050-01-01")),
                          raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio02", experiment = "rcp85", future_date = "2050-01-01")),
                          raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio03", experiment = "rcp85", future_date = "2050-01-01")),
                          raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio04", experiment = "rcp85", future_date = "2050-01-01")),
                          raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio05", experiment = "rcp85", future_date = "2050-01-01")),
                          raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio06", experiment = "rcp85", future_date = "2050-01-01")),
                          raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio07", experiment = "rcp85", future_date = "2050-01-01")),
                          raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio08", experiment = "rcp85", future_date = "2050-01-01")),
                          raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio09", experiment = "rcp85", future_date = "2050-01-01")),
                          raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio10", experiment = "rcp85", future_date = "2050-01-01")),
                          raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio11", experiment = "rcp85", future_date = "2050-01-01")),
                          raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio12", experiment = "rcp85", future_date = "2050-01-01")),
                          raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio13", experiment = "rcp85", future_date = "2050-01-01")),
                          raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio14", experiment = "rcp85", future_date = "2050-01-01")),
                          raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio15", experiment = "rcp85", future_date = "2050-01-01")),
                          raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio16", experiment = "rcp85", future_date = "2050-01-01")),
                          raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio17", experiment = "rcp85", future_date = "2050-01-01")),
                          raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio18", experiment = "rcp85", future_date = "2050-01-01")),
                          raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio19", experiment = "rcp85", future_date = "2050-01-01"))
  )
  
  sendstatus("Writing Copernicus Future 2050 8.5")
  rpostgis::pgWriteRast(con,
                        name = "future_2050_8_5", raster = future, overwrite = TRUE
  )
  rm(future)
  gc()
} else {
  cat("Raster layers exist in Postgres. Skipping. ")
}

########################## Future 2070 4.5 Raster ############################
if (!RPostgres::dbExistsTable(conn = con, name = "future_2070_4_5")) {
  sendstatus("starting with reading Copernicus Future 2070 4.5")
  future <- raster::stack(raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio01", experiment = "rcp45", future_date = "2070-01-01")),
                          raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio02", experiment = "rcp45", future_date = "2070-01-01")),
                          raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio03", experiment = "rcp45", future_date = "2070-01-01")),
                          raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio04", experiment = "rcp45", future_date = "2070-01-01")),
                          raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio05", experiment = "rcp45", future_date = "2070-01-01")),
                          raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio06", experiment = "rcp45", future_date = "2070-01-01")),
                          raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio07", experiment = "rcp45", future_date = "2070-01-01")),
                          raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio08", experiment = "rcp45", future_date = "2070-01-01")),
                          raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio09", experiment = "rcp45", future_date = "2070-01-01")),
                          raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio10", experiment = "rcp45", future_date = "2070-01-01")),
                          raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio11", experiment = "rcp45", future_date = "2070-01-01")),
                          raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio12", experiment = "rcp45", future_date = "2070-01-01")),
                          raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio13", experiment = "rcp45", future_date = "2070-01-01")),
                          raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio14", experiment = "rcp45", future_date = "2070-01-01")),
                          raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio15", experiment = "rcp45", future_date = "2070-01-01")),
                          raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio16", experiment = "rcp45", future_date = "2070-01-01")),
                          raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio17", experiment = "rcp45", future_date = "2070-01-01")),
                          raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio18", experiment = "rcp45", future_date = "2070-01-01")),
                          raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio19", experiment = "rcp45", future_date = "2070-01-01"))
  )
  
  sendstatus("Writing Copernicus Future 2070 4.5")
  rpostgis::pgWriteRast(con,
                        name = "future_2070_4_5", raster = future, overwrite = TRUE
  )
  rm(future)
  gc()
} else {
  cat("Raster layers exist in Postgres. Skipping. ")
}


########################## Future 2070 8.5 Raster ############################
if (!RPostgres::dbExistsTable(conn = con, name = "future_2070_8_5")) {
  sendstatus("starting with reading Copernicus Future 2070 8.5")
  future <- raster::stack(raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio01", experiment = "rcp85", future_date = "2070-01-01")),
                          raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio02", experiment = "rcp85", future_date = "2070-01-01")),
                          raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio03", experiment = "rcp85", future_date = "2070-01-01")),
                          raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio04", experiment = "rcp85", future_date = "2070-01-01")),
                          raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio05", experiment = "rcp85", future_date = "2070-01-01")),
                          raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio06", experiment = "rcp85", future_date = "2070-01-01")),
                          raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio07", experiment = "rcp85", future_date = "2070-01-01")),
                          raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio08", experiment = "rcp85", future_date = "2070-01-01")),
                          raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio09", experiment = "rcp85", future_date = "2070-01-01")),
                          raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio10", experiment = "rcp85", future_date = "2070-01-01")),
                          raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio11", experiment = "rcp85", future_date = "2070-01-01")),
                          raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio12", experiment = "rcp85", future_date = "2070-01-01")),
                          raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio13", experiment = "rcp85", future_date = "2070-01-01")),
                          raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio14", experiment = "rcp85", future_date = "2070-01-01")),
                          raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio15", experiment = "rcp85", future_date = "2070-01-01")),
                          raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio16", experiment = "rcp85", future_date = "2070-01-01")),
                          raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio17", experiment = "rcp85", future_date = "2070-01-01")),
                          raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio18", experiment = "rcp85", future_date = "2070-01-01")),
                          raster::raster(getfutureclimate(source = "copernicus", bioclim = "bio19", experiment = "rcp85", future_date = "2070-01-01"))
  )
  
  sendstatus("Writing Copernicus Future 2070 8.5")
  rpostgis::pgWriteRast(con,
                        name = "future_2070_8_5", raster = future, overwrite = TRUE
  )
  rm(future)
  gc()
} else {
  cat("Raster layers exist in Postgres. Skipping. ")
}
  
  
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
  
  
  print("Writing Soil to DB")
  rpostgis::pgWriteRast(con,
                        name = "soil", raster = soil, overwrite = TRUE
  )
  rm(soil)
  gc()
  




DBI::dbDisconnect(conn = con)