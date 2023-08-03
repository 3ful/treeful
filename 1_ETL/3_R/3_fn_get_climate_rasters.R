##################### Function to Get  climate Rasters ##################
# In theory they can easily be adjusted to other climate raster providers. For some, snippets exist in the functions already but probably wont work 
# in the entire workflow of treeful. All processing here is only tested with Copernicus
# you pass a provider and a bioclimatic var like bio01 or bio13 to the function and it returns one raster. you can stack them later on. 


getpastclimate <- function(source = "copernicus", bioclim = "bio01") {
  if (source == "climateeu") {
    bio_path <- case_when(bioclim == "bio01" ~ "MAT",
                          bioclim == "bio12" ~ "MAP",
                          )
    
    bio_raster <- raster(paste0("data/climateEU/Normal_1961-1990_bioclim/", bio_path, ".asc"))

    raster::crs(bio_raster) <- "+proj=aea +lat_0=30 +lon_0=10 +lat_1=43 +lat_2=62 +x_0=0 +y_0=0 +ellps=intl +units=m +no_defs +type=crs"
    
    bio_raster <- raster::projectRaster(bio_raster, crs = 4326)
    
  }
  
  if (source == "copernicus") {
    # Get bioclimate data from copernicus. Download bioclimate file with login at https://cds.climate.copernicus.eu/
    
    bio_path <- toupper(bioclim)

    bio_raster <- terra::rast(paste0("2_Data/0_raw_data/past/", bio_path, "_era5-to-1km_1979-2018-mean_v1.0.nc"))
    # convert bioclim as per copernicus documentation. for some reasone case_when does not work here.     
    if (bioclim %in% c("bio01", "bio02", "bio04", "bio05", "bio06", "bio07", "bio08", "bio09", "bio10", "bio11")) 
    {bio_raster <- bio_raster - 273.15
    } else if (bioclim == "bio12") {bio_raster <- bio_raster*3600*24*365*1000
    } else if (bioclim %in% c("bio13", "bio14")) {bio_raster <- bio_raster*3600*24*30.5*1000
    } else if (bioclim %in% c("bio16", "bio17", "bio18", "bio19")) {bio_raster <- bio_raster*3600*24*91.3*1000
    }
    # a bit unclear if bio13-bio19 can and should also be comverted like bio12. probably not as theyre not on annual reference period

    
  }
  # worldclim would be great cause it fetches all 19 bioclimatic at once. and has a great time range from 1970-2000. 
  # but units of each var are stange. 

  if (source == "worldclim") {
    
    bio_path <- case_when(bioclim == "bio01" ~ "bio_1",
                          bioclim == "bio02" ~ "bio_2",
                          bioclim == "bio03" ~ "bio_3",
                          bioclim == "bio04" ~ "bio_4",
                          bioclim == "bio05" ~ "bio_5",
                          bioclim == "bio06" ~ "bio_6",
                          bioclim == "bio07" ~ "bio_7",
                          bioclim == "bio08" ~ "bio_8",
                          bioclim == "bio09" ~ "bio_9",
                          bioclim == "bio10" ~ "bio_10",
                          bioclim == "bio11" ~ "bio_11",
                          bioclim == "bio12" ~ "bio_12",
                          bioclim == "bio13" ~ "bio_13",
                          bioclim == "bio14" ~ "bio_14",
                          bioclim == "bio15" ~ "bio_15",
                          bioclim == "bio16" ~ "bio_16",
                          bioclim == "bio17" ~ "bio_17",
                          bioclim == "bio18" ~ "bio_18",
                          bioclim == "bio19" ~ "bio_19"
    )
    
    bio_raster <- raster(paste0("2_Data/1_output/worldclim_cropped/wc2.1_30s_", bio_path, ".tif"))
    

  }
  
  if (source == "chelsa") {
    
    bio_path <- case_when(bioclim == "bio01" ~ "bio1",
                          bioclim == "bio12" ~ "bio12"
    )
    
    bio_raster <- raster(paste0("2_Data/1_output/CHELSA_cropped/CHELSA_", bio_path, "_1981-2010_V.2.1.tif"))
    
    if (bioclim == "bio01") {bio_raster <- raster::calc(bio_raster, function(x) { x / 10 - 273.15 })
    } else if (bioclim == "bio12") {
      bio_raster <- raster::calc(bio_raster, function(x) { x / 10})
    }
    
    
  }
  
  
  return(bio_raster)
  
  
}


#################### Get Future Climate ##################
# for now using climate projection model MPI-ESM1-2-LR and socio-econ pathway 245 

getfutureclimate <- function(source = "copernicus", bioclim = "bio01") {
  if(source == "chelsa") {
    future_raster <- raster::stack(c("2_Data/1_output/CHELSA_cropped/CHELSA_bio1_2041-2070_gfdl-esm4_ssp370_V.2.1.tif", 
                    "2_Data/1_output/CHELSA_cropped/CHELSA_bio12_2041-2070_gfdl-esm4_ssp370_V.2.1.tif"))
    names(future_raster)[1] <- "bio01"
    names(future_raster)[2] <- "bio12"
    future_raster$bio01 <- raster::calc(future_raster$bio01, function(x) { x / 10 - 273.15 })
    future_raster$bio12 <- raster::calc(future_raster$bio12, function(x) { x / 10})
    
  } else if (source == "worldclim") {
    future_raster <- geodata::cmip6_tile(model = "MPI-ESM1-2-LR", lon = 11.01684, lat = 51.28691, 
                                         ssp = "245", time = "2041-2060", var = "bioc", path = "2_Data/0_raw_data/", res = 5)
    names(future_raster)[1] <- "bio01"
    names(future_raster)[12] <- "bio12"
  } else if (source == "copernicus") {

    bio_path <- toupper(bioclim)

    bio_raster <- terra::rast(paste0("2_Data/0_raw_data/future/", bio_path, "_hadgem2-cc_rcp45_r1i1p1_1960-2099-mean_v1.0.nc"))
    #$X2050.01.01
    names(bio_raster) <- terra::time(bio_raster)
    bio_raster <- bio_raster$`2050-01-01`
    # convert bioclim as per copernicus documentation. for some reason case_when does not work here.     
    if (bioclim %in% c("bio01", "bio02", "bio04", "bio05", "bio06", "bio07", "bio08", "bio09", "bio10", "bio11")) 
    {bio_raster <- bio_raster - 273.15
    } else if (bioclim == "bio12") {bio_raster <- bio_raster*3600*24*365*1000
    } else if (bioclim %in% c("bio13", "bio14")) {bio_raster <- bio_raster*3600*24*30.5*1000
    } else if (bioclim %in% c("bio16", "bio17", "bio18", "bio19")) {bio_raster <- bio_raster*3600*24*91.3*1000
    }
    
  }
  
  return(bio_raster)
}

getsoilproperties <- function(variable = "STU_EU_DEPTH_ROOTS") {
  soil_layer <- terra::rast(paste0("2_Data/0_raw_data/soil/", variable, "_4326.tif"))
  return(soil_layer)
}
