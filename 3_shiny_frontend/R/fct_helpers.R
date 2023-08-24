#' helpers
#'
#' @description A fct function
#'
#' @return The return value, if any, from executing the function.
#'
#' @noRd

backend_con <- pool::dbPool(RPostgres::Postgres(),
                            dbname = "treeful-test",
                            #host= "192.168.178.148",
                            host= "db",
                            port="5432",
                            user="postgres",
                            #password="mysecretpassword")
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
