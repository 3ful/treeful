#' helpers
#'
#' @description A fct function
#'
#' @return The return value, if any, from executing the function.
#'
#' @noRd

backend_con <- pool::dbPool(RPostgres::Postgres(),
                            dbname = "treeful-test",
                            host= "192.168.178.148",
                            #host= "db",
                            port="5432",
                            user="postgres",
                            #password=read_lines(Sys.getenv("POSTGRES_PW_FILE")))
                            password=Sys.getenv("POSTGRES_PW"))
onStop(function() {
  pool::poolClose(backend_con)
})

species <- DBI::dbGetQuery(backend_con, paste0("SELECT * FROM tree_master_list")) %>%
  dplyr::arrange(latin_name)

# cobble together query, used for user climate
make_query <- function(map_point = map_point(), layer = "", band = dplyr::filter(biovars, biovars == input$select_biovar)$rowid) {
  return(paste0("SELECT g.pt_geom, ST_Value(ST_Band(r.rast, ARRAY[", band, "]), g.pt_geom) AS biovar
        FROM public.", layer, " AS r
        INNER JOIN
        (SELECT ST_Transform(ST_SetSRID(ST_MakePoint(", map_point$lon, ",", map_point$lat, "), 4326),4326) As pt_geom) AS g
        ON r.rast && g.pt_geom;"))
}

get_biolayer <- function(band = 1, layer = "past", map_point = map_point()) {
  biovar <- RPostgreSQL::dbGetQuery(backend_con, make_query(map_point = map_point, layer = layer, band = band))$biovar
  return(biovar)
}

# function to extract all biovars from raster files on disk for user location, projection scenario and future date
bio_extract <- function(map_point. = map_point, experiment = "rcp45", future_date = 5) {

  ##### Get Past values
  bio_past <- terra::extract(x = terra::rast(paste0("../1_ETL/2_Data/0_raw_data/past/", biovars$biovars, "_era5-to-1km_1979-2018-mean_v1.0.nc")),
                             y = map_point.)

  ###### Get Future Values
  ###### CAREFUL, future_date is index of raster. 5 = 2050, 6 = 2070, 7 = 2090
  #bio_dates <- c("1979-01-01", "1989-01-01", "2009-01-01", "2030-01-01", "2050-01-01", "2070-01-01", "2090-01-01")

  future_raster <- terra::subset(
    terra::rast(paste0("../1_ETL/2_Data/0_raw_data/future/", biovars$biovars, "_noresm1-m_",
                                                 experiment, "_r1i1p1_1960-2099-mean_v1.0.nc")),
                              paste0(biovars$biovars, "_", future_date))

  bio_future <- terra::extract(x = future_raster, y = map_point.) %>%
    dplyr::rename_with(everything(), .fn = ~ stringr::str_remove(.x, "_(5|6|7)"))
  rm(future_raster)

  ###### Get Soil Values
  soil_layer <- terra::rast(paste0("../1_ETL/2_Data/0_raw_data/soil/", soil_vars$soilvars, "_4326.tif"))
  bio_soil <- terra::extract(x = soil_layer, y = map_point)

  bio_past %>%
    dplyr::mutate(dimension = "past") %>%
    dplyr::bind_rows(dplyr::mutate(bio_future, dimension = "future")) %>%
  # when temp, conert from kelvin to degree
    dplyr::mutate(across(.cols = ends_with(c("01", "05", "06", "08", "09", "10", "11")), ~ (.x - 273.15), .names = "{.col}")) %>%
    # when annual precip, compute for 365 days
    dplyr::mutate(across(.cols = ends_with(c("12")), ~ (.x *3600*24*365*1000), .names = "{.col}")) %>%
    # when monthly preci, computer for month
    dplyr::mutate(across(.cols = ends_with(c("13", "14")), ~ (.x *3600*24*30.5*1000), .names = "{.col}")) %>%
    # when quarterly precip compute for 91.3 days.
    dplyr::mutate(across(.cols = ends_with(c("16", "17", "18", "19")), ~ (.x *3600*24*91.3*1000), .names = "{.col}")) %>%
    dplyr::bind_rows(dplyr::mutate(bio_soil, dimension = "soil")) %>%
    dplyr::select(dimension, dplyr::everything(), -ends_with("_ID")) %>%
    return(.)



}



