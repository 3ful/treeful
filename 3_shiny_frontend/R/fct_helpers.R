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
# make_query <- function(map_point = map_point(), layer = "", band = dplyr::filter(biovars, biovars == input$select_biovar)$rowid) {
#   return(paste0("SELECT g.pt_geom, ST_Value(ST_Band(r.rast, ARRAY[", band, "]), g.pt_geom) AS biovar
#         FROM public.", layer, " AS r
#         INNER JOIN
#         (SELECT ST_Transform(ST_SetSRID(ST_MakePoint(", map_point$lon, ",", map_point$lat, "), 4326),4326) As pt_geom) AS g
#         ON r.rast && g.pt_geom;"))
# }
#
# get_biolayer <- function(band = 1, layer = "past", map_point = map_point()) {
#   biovar <- RPostgreSQL::dbGetQuery(backend_con, make_query(map_point = map_point, layer = layer, band = band))$biovar
#   return(biovar)
# }

# function to extract all biovars from raster files on disk for user location, projection scenario and future date
bio_extract <- function(map_point. = map_point, experiment = "rcp45", future_date = 5) {

  ##### Get Past values
  bio_past <- terra::extract(x = terra::rast(paste0("data/past/", biovars$biovars, "_era5-to-1km_1979-2018-mean_v1.0.nc")),
                             y = map_point.)

  ###### Get Future Values
  ###### CAREFUL, future_date is index of raster. 5 = 2050, 6 = 2070, 7 = 2090
  #bio_dates <- c("1979-01-01", "1989-01-01", "2009-01-01", "2030-01-01", "2050-01-01", "2070-01-01", "2090-01-01")

  future_raster <- terra::subset(
    terra::rast(paste0("data/future/", biovars$biovars, "_noresm1-m_",
                                                 experiment, "_r1i1p1_1960-2099-mean_v1.0.nc")),
                              paste0(biovars$biovars, "_", future_date))

  bio_future <- terra::extract(x = future_raster, y = map_point.) %>%
    dplyr::rename_with(everything(), .fn = ~ stringr::str_remove(.x, "_(4|5|6|7)"))
  rm(future_raster)

  ###### Get Soil Values
  soil_layer <- terra::rast(paste0("data/soil/", soil_vars$soilvars, "_4326.tif"))
  bio_soil <- terra::extract(x = soil_layer, y = map_point.)

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








percentile_ranges <- DBI::dbReadTable(conn = backend_con, "percentile_ranges")

closest_match <- function(biovar_match = biovar, user_climate = user_climate_wide()) {
  sought <- as.numeric(dplyr::select(dplyr::filter(user_climate, dimension == "future"), all_of(biovar_match)))

  percentile_ranges %>%
    filter(bioclim_variable ==  biovar_match) %>%
    group_by(species) %>%
    filter(abs(value - sought) == min(abs(value - sought))) %>%
    group_by(species, bioclim_variable) %>%
    summarise(centile = max(abs(centile)), .groups = "drop") %>%
    ungroup()

}


make_explorer_cards <- function(tree_image = image_url, tree_descr = species, gbif = gbif_taxo_id, wikipedia = url) {
  tree_descr <- str_replace_all(tree_descr, "\\s", "_")

  card(
    max_height = "90vh",
    full_screen = T,
    tags$img(src =  paste0("https://", tree_image), class = "card-img-top"),
    #card_image(file = NULL, src = paste0("https://", tree_image)) ,
    p(class = "text-muted", htmltools::includeMarkdown(file.path("inst", "app", "www", "tree_profiles", paste0(tree_descr, ".md")))),
    tags$a(paste0(tree_descr, " bei GBIF"),
           href = paste0("https://www.gbif.org/species/", gbif),
           target = "_blank"),
    tags$a(paste0(tree_descr, " bei Wikipedia"),
           href = wikipedia,
           target = "_blank")

  )
  #bslib::card_image(file = paste0("https://", tree_image))
}



make_cards <- function(tree_index = rowid, tree_image = image_url, tree_descr = species, gbif = gbif_taxo_id, wikipedia = url, score = summed_score) {
  tree_descr <- str_replace_all(tree_descr, "\\s", "_")

  card(
    max_height = "40vh",
    full_screen = T,
    card_header(
      tags$b(paste0("Rang ", tree_index)),tags$em(paste0(": ", score, "/1386")),

    ),
    layout_sidebar(
      fillable = TRUE,
      sidebar = sidebar(
        tags$img(src = paste0("https://", tree_image), max_height = "20vh"),
        tags$a(paste0(tree_descr, " bei GBIF"),
               href = paste0("https://www.gbif.org/species/", gbif),
               target = "_blank"),
        tags$a(paste0(tree_descr, " bei Wikipedia"),
               href = wikipedia,
               target = "_blank")
      ),
      p(class = "text-muted", includeMarkdown(file.path("inst", "app", "www", "tree_profiles", paste0(tree_descr, ".md"))))
    )
  )
    #bslib::card_image(file = paste0("https://", tree_image))
}

col_primary = "#6e944eff"
col_secondary = "#deeed4ff"
col_fg = "#2b2b40ff"
col_warning = "#c65534c5"
col_danger = "#c75634ff"

#
#
# ranking_suitability <- function() {
#
#   just_test <- tst$BIO01[2]
#
#   dplyr::tbl(backend_con, "percentile_ranges") %>%
#     # dplyr::select(c("BIO01", "BIO05", "BIO06", "BIO08", "BIO09", "BIO11", "BIO11",
#     #                 "BIO12", "BIO13", "BIO14", "BIO16", "BIO17", "BIO18", "BIO19")) %>%
#     #dplyr::select(c("BIO01")) %>%
#     filter(species == "Abies alba" & bioclim_variable == "BIO01") %>%
#     arrange(abs(value - just_test))
#     # tbl(sql("SELECT * FROM public.percentile_ranges
#     # WHERE species = 'Abies alba' and bioclim_variable = 'BIO01'
#     #         ORDER BY ABS( value - 8) "))
#     filter(bioclim_variable == "BIO01" & abs(.$value - tst$BIO01[2]) == min(abs(.$value - tst$BIO01[2])))
#     # filter(ActivityTypeNameOfActivity %in% c("Assistance/support transmitted") &
#     #          StatusCodeOfBeneficiary == "Operational Data") %>%
#     # filter(ActivityPrecisionNameOfActivity %in% c("PROT - Ad hoc assistance", "Socio-economic", "PROT - Funeral reimbursement") |
#     #          is.na(ActivityPrecisionNameOfActivity)) %>%
#     #filter(FileIDOfBeneficiary =="UAK-106253-01") %>%
#     filter(history_id == "70db42d6-30a6-ed11-83af-005056940158") %>%
#     distinct() %>%
#     collect()
#
# }
#
#
#
#
