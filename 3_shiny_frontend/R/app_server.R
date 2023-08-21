#' The application server-side
#'
#' @param input,output,session Internal parameters for {shiny}.
#'     DO NOT REMOVE.
#' @import shiny
#' @import data.table
#' @import paletteer
#' @import tidyverse
#' @import hrbrthemes
#' @import leaflet
#' @import DT
#' @import sf
#' @import raster
#' @import rpostgis
#' @import DBI
#' @import wesanderson
#' @import ggplot2
#' @import tibble
#' @noRd

# library(tidyverse)
# library(hrbrthemes)
# library(paletteer)
# library(leaflet)
# #library(sf)
# #library(raster)
# library(ggplot2)
# library(tibble)

biovars <- tibble::tibble(biovars = c("BIO01", "BIO02", "BIO03", "BIO04", "BIO05", "BIO06", "BIO07", "BIO08", "BIO09",
                              "BIO10", "BIO11", "BIO12", "BIO13", "BIO14", "BIO15", "BIO16", "BIO17", "BIO18", "BIO19"),
                          descr_de = c("Jahresdurchschnittstemperatur", "Tagestemperaturspanne", "Isothermalität",
                                              "Temperatur-Saisonalität", "Maximaltemperatur des wärmsten Monats",
                                              "Minimaltemperatur des kältesten Monats", "Jahrestemperaturspanne",
                                              "Durchschnittstemperatur des feuchtesten Quartals", "Durchschnittstemperatur des trockensten Quartals",
                                              "Durchschnittstemperatur des wärmsten Quartals", "Durchschnittstemperatur des kältesten Quartals",
                                              "Jahresniederschlag", "Niederschlag im feuchtesten Monat", "Niederschlag im trockensten Monat",
                                              "Niederschlags-Saisonalität", "Niederschlag im feuchtesten Quartal", "Niederschlag im trockensten Quartal",
                                              "Niederschlag im wärmsten Quartal", "Niederschlag im kältesten Quartal"
                                              )) %>%
  rowid_to_column()
biovars_c <- c("BIO01" = 1, "BIO02" = 2, "BIO03" = 3, "BIO04" = 4, "BIO05" = 5, "BIO06" = 6, "BIO07" = 7, "BIO08" = 8, "BIO09" = 9,
               "BIO10" = 10, "BIO11" = 11, "BIO12" = 12, "BIO13" = 13, "BIO14" = 14, "BIO15" = 15, "BIO16" = 16, "BIO17" = 17,
               "BIO18" = 18, "BIO19" = 19)

soil_vars_c <- c("STU_EU_DEPTH_ROOTS" = 1,"STU_EU_T_CLAY" = 2,"STU_EU_S_CLAY" = 3,"STU_EU_T_SAND" = 4,"STU_EU_S_SAND" = 5,"STU_EU_T_SILT" = 6,
                 "STU_EU_S_SILT" = 7, "STU_EU_T_OC" = 8,"STU_EU_S_OC" = 9,"STU_EU_T_BD" = 10,"STU_EU_S_BD" = 11,
                 "STU_EU_T_GRAVEL" = 12,"STU_EU_S_GRAVEL" = 13, "SMU_EU_T_TAWC" = 14,"SMU_EU_S_TAWC" = 15,
                 "STU_EU_T_TAWC" = 16, "STU_EU_S_TAWC" = 17)

soil_vars <- tibble::tibble(soilvars = c("STU_EU_DEPTH_ROOTS","STU_EU_T_CLAY","STU_EU_S_CLAY","STU_EU_T_SAND","STU_EU_S_SAND","STU_EU_T_SILT","STU_EU_S_SILT",
                                         "STU_EU_T_OC","STU_EU_S_OC","STU_EU_T_BD","STU_EU_S_BD","STU_EU_T_GRAVEL","STU_EU_S_GRAVEL",
                                         "SMU_EU_T_TAWC","SMU_EU_S_TAWC","STU_EU_T_TAWC", "STU_EU_S_TAWC"),
                          descr_de = c("Wurzelverfügbare Tiefe cm", "Tonanteil % Oberboden", "Tonanteil % Unterboden",
                                       "Sandanteil % Oberboden", "Sandanteil % Unterboden",
                                       "Schluffanteil % Oberboden", "Schluffanteil % Unterboden",
                                       "Anteil org. Kohlenstoff % Oberboden", "Anteil org. Kohlenstoff % Unterboden",
                                       "Schüttdichte Oberboden g/cm^3", "Schüttdichte Unterboden g/cm^3",
                                       "Anteil grobkörniger Fragmente % Oberboden", "Anteil grobkörniger Fragmente % unterboden",
                                       "Insges. verfügbarer Wassergehalt (PTR) Oberboden mm", "Insges. verfügbarer Wassergehalt (PTR) Unterboden mm",
                                       "Insges. verfügbarer Wassergehalt (PTF) Oberboden mm", "Insges. verfügbarer Wassergehalt (PTF) Unterboden mm"
                          )) %>%
  rowid_to_column()


app_server <- function(input, output, session) {
  # Your application server logic

  username <- Sys.getenv("SHINYPROXY_USERNAME")
  Sys.setlocale("LC_TIME","de_DE.UTF-8")

  backend_con <- DBI::dbConnect(RPostgres::Postgres(),
                        dbname = "treeful-test",
                        host= "192.168.178.148",
                        port="5432",
                        user="postgres",
                        password="mysecretpassword")
  session$onSessionEnded(function() {
    DBI::dbDisconnect(backend_con)
  })

  output$map <- renderLeaflet({leaflet()%>% addTiles() %>% leaflet.extras::addSearchOSM()})

  observe({
    click <- input$map_click
    req(click)
    leafletProxy('map') %>% clearMarkers()
    leafletProxy('map')%>% addMarkers(lng = click$lng, lat = click$lat)

  })

  # construct user point as sf
  map_point <-
    reactive({
      sf::st_as_sf(tibble::tibble(lat = input$map_click$lat, lon = input$map_click$lng), coords = c("lon", "lat"), crs = 4326, remove =FALSE)
    })

  # cobble together query, used for user climate
  make_query <- function(map_point = map_point(), layer = "", band = dplyr::filter(biovars, biovars == input$select_biovar)$rowid) {
    return(paste0("SELECT g.pt_geom, ST_Value(ST_Band(r.rast, ARRAY[", band, "]), g.pt_geom) AS biovar
      FROM public.", layer, " AS r
      INNER JOIN
      (SELECT ST_Transform(ST_SetSRID(ST_MakePoint(", map_point$lon, ",", map_point$lat, "), 4326),4326) As pt_geom) AS g
      ON r.rast && g.pt_geom;"))
  }


  # getting past and future for one biovar from one location
  get_user_climate <- function(connection = backend_con, map_point = map_point(),
                               user_biovar = dplyr::filter(biovars, biovars == input$select_biovar)$rowid) {


    #get past at map location
    bio_hist <- RPostgreSQL::dbGetQuery(backend_con,make_query(map_point, layer = "past", band = user_biovar)) %>%
      dplyr::select(-pt_geom, past = biovar)
    bio_future <- RPostgreSQL::dbGetQuery(backend_con,make_query(map_point, layer = "future", band = user_biovar)) %>%
      dplyr::select(-pt_geom, future = biovar)

    return(tibble::tibble(bio_future, bio_hist))
  }


  get_biolayer <- function(band = 1, layer = "past", map_point = map_point()) {
    biovar <- RPostgreSQL::dbGetQuery(backend_con,make_query(map_point = map_point, layer = layer, band = band))$biovar
    return(biovar)
  }
  # get_biolayer <- function(band = 1, layer = "past") {
  #   biovar <- RPostgreSQL::dbGetQuery(backend_con,make_query(map_point, layer = layer, band = band))$biovar
  #   return(biovar)
  # }

  user_climate1 <- reactive({
    req(input$map_click)
      get_user_climate(connection = backend_con, map_point = map_point(),
                       user_biovar = dplyr::filter(biovars, biovars == input$select_single_biovar)$rowid[1])
    })

  user_climate_wide <- reactive({
    req(input$map_click)
    # tibble::tibble(
    #   get_user_climate(connection = backend_con, lat = input$map_click$lat, lon = input$map_click$lng,
    #                    user_biovar = dplyr::filter(biovars, biovars == input$select_biovar1)$rowid[1]) %>%
    #     dplyr::select(past1 = past, future1 = future),
    #   get_user_climate(connection = backend_con, lat = input$map_click$lat, lon = input$map_click$lng,
    #                    user_biovar = dplyr::filter(biovars, biovars == input$select_biovar2)$rowid[1]) %>%
    #     dplyr::select(past2 = past, future2 = future)
    #
      past_biovars <- purrr::map_dfr(biovars_c, get_biolayer, layer = "past", map_point = map_point())  %>% dplyr::mutate(layer = "past")
      future_biovars <- purrr::map_dfr(biovars_c, get_biolayer, layer = "future", map_point = map_point())  %>% dplyr::mutate(layer = "future")
      soil <- purrr::map_dfr(soil_vars_c, get_biolayer, layer = "soil", map_point = map_point()) %>% dplyr::mutate(layer = "soil")
      dplyr::bind_rows(past_biovars, future_biovars, soil)
  })
  user_climate_long <- reactive({
    req(input$map_click)
    past_biovars <- purrr::map_dfr(biovars_c, get_biolayer, layer = "past", map_point = map_point()) %>% tidyr::pivot_longer(everything()) %>% dplyr::mutate(layer = "past")
    future_biovars <- purrr::map_dfr(biovars_c, get_biolayer, layer = "future", map_point = map_point()) %>% tidyr::pivot_longer(everything()) %>% dplyr::mutate(layer = "future")
    soil <- purrr::map_dfr(soil_vars_c, get_biolayer, layer = "soil", map_point = map_point()) %>% tidyr::pivot_longer(everything()) %>% dplyr::mutate(layer = "soil")
    dplyr::bind_rows(past_biovars, future_biovars, soil)
  })

  output$user_location <- DT::renderDT(user_climate_long())

  #tree_db <- data.table::fread("data/tree_db.csv")
  species <- DBI::dbGetQuery(backend_con, paste0("SELECT * FROM tree_master_list")) %>%
    dplyr::arrange(latin_name)

  # trees_quantiles <- DBI::dbGetQuery(backend_con, paste0("SELECT * FROM trees_quantiles"))
  # trees_quantiles <- tidyr::pivot_longer(trees_quantiles, cols = dplyr::ends_with(c("_val"))) %>%
  #   dplyr::select(dplyr::everything(), -dplyr::ends_with("quant"), -unpack, "bio01_quant") %>%
  #   dplyr::rename(quart = bio01_quant) %>%
  #   dplyr::mutate(name = toupper(stringr::str_remove(name, "_val")))


  updateSelectInput(session, "select_species", choices = species$latin_name, selected = "Sorbus torminalis")

  # tree_occurrence <- reactive(tree_db[master_list_name %in% c(input$select_species), ]
  # )
  #selection <- reactive(input$select_species)

  tree_occurrence <- reactive(
    DBI::dbGetQuery(backend_con, paste0(
      "SELECT * FROM tree_dbs WHERE master_list_name ='", input$select_species, "';"))
  )

  output$selected_species_control <- renderText({ paste0(nrow(tree_occurrence()), " Baumstandorte gefunden") })

  output$selected_species_descr <- renderText({ dplyr::filter(species, latin_name == input$select_species)$descr_de })
  output$selected_species_img <- renderUI({
    tags$img(src = paste0("https://", dplyr::filter(species, latin_name == input$select_species)$image_url))
  })

  # output$user_input_plot <- renderPlot({
  #   ggplot2::ggplot(data = user_climate1()) +
  #     ggplot2::geom_point(aes(x = bio12_hist, y = bio01_hist), color = "blue") +
  #     ggplot2::geom_label(aes(x = bio12_hist, y = bio01_hist, label = "Klima 1979-2018")) +
  #     ggplot2::geom_point(aes(x = bio12_future, y = bio01_future), color = "darkred") +
  #     ggplot2::geom_label(aes(x = bio12_future, y = bio01_future, label = "Klima 2050")) +
  #     ggplot2::geom_segment(aes(x = bio12_hist, y = bio01_hist, xend = bio12_future, yend = bio01_future), color = "black") +
  #     hrbrthemes::theme_ipsum() +
  #     ggplot2::labs(title = paste0("Jahrestemperatur und Jahresniederschlag am gewählten Standort"),
  #          subtitle = paste0(""))
  # })

  output$species_plot <- renderPlot({
    ggplot2::ggplot(data = tree_occurrence()) +
    ggplot2::geom_point(ggplot2::aes(x = .data[[dplyr::filter(biovars, biovars == input$select_biovar1[1])$biovars]],
                            y = .data[[dplyr::filter(biovars, biovars == input$select_biovar2[1])$biovars]], color = db),
                        alpha = 0.1, stroke = 0) +
    #geom_hex(aes(x = bio12_copernicus_1979_2018, y = bio01_copernicus_1979_2018), bins = 70) +
    #stat_density_2d(aes(x = bio12_copernicus_1979_2018, y = bio01_copernicus_1979_2018, fill = ..level..), geom = "polygon", colour="white") +
    ggplot2::geom_point(data = dplyr::filter(user_climate_wide(), layer %in% c("past", "future")),
                        ggplot2::aes(x = .data[[dplyr::filter(biovars, biovars == input$select_biovar1[1])$biovars]],
                                     y = .data[[dplyr::filter(biovars, biovars == input$select_biovar2[1])$biovars]]),
                        color = "darkolivegreen4", size = 4) +
    scale_color_paletteer_d("wesanderson::Royal1") +
    #ggplot2::facet_wrap(~master_list_name) +
    hrbrthemes::theme_ipsum() +
    ggplot2::labs(title = paste0(dplyr::filter(biovars, biovars == input$select_biovar1[1])$descr_de, " und ",
                                 dplyr::filter(biovars, biovars == input$select_biovar2[1])$descr_de),
                  x = dplyr::filter(biovars, biovars == input$select_biovar1[1])$descr_de,
                  y = dplyr::filter(biovars, biovars == input$select_biovar2[1])$descr_de,
         subtitle = paste0("")) +
      ggplot2::theme(
        plot.background = element_rect(fill = "#222222"),
        text = element_text(color = "white"),
        strip.text = element_text(color = "white"),
        axis.title.y = element_text(size = 20),
        axis.title.x = element_text(size = 20)
        )
  })


  output$soil_plot <- renderPlot({
    ggplot2::ggplot(data = tree_occurrence()) +
      ggplot2::geom_point(ggplot2::aes(x = .data[[dplyr::filter(soil_vars, soilvars == input$select_soilvar1[1])$soilvars]],
                                       y = .data[[dplyr::filter(soil_vars, soilvars == input$select_soilvar2[1])$soilvars]], color = db),
                          alpha = 0.1, stroke = 0) +
      #geom_hex(aes(x = bio12_copernicus_1979_2018, y = bio01_copernicus_1979_2018), bins = 70) +
      #stat_density_2d(aes(x = bio12_copernicus_1979_2018, y = bio01_copernicus_1979_2018, fill = ..level..), geom = "polygon", colour="white") +
      ggplot2::geom_point(data = dplyr::filter(user_climate_wide(), layer %in% c("soil")),
                          ggplot2::aes(x = .data[[dplyr::filter(soil_vars, soilvars == input$select_soilvar1[1])$soilvars]],
                                       y = .data[[dplyr::filter(soil_vars, soilvars == input$select_soilvar2[1])$soilvars]]),
                          color = "darkolivegreen4", size = 4) +
      scale_color_paletteer_d("wesanderson::Royal1") +
      #ggplot2::facet_wrap(~master_list_name) +
      hrbrthemes::theme_ipsum() +
      ggplot2::labs(title = paste0(dplyr::filter(soil_vars, soilvars == input$select_soilvar1[1])$descr_de, " und ",
                                   dplyr::filter(soil_vars, soilvars == input$select_soilvar2[1])$descr_de),
                    x = dplyr::filter(soil_vars, soilvars == input$select_soilvar1[1])$descr_de,
                    y = dplyr::filter(soil_vars, soilvars == input$select_soilvar2[1])$descr_de,
                    subtitle = paste0("")) +
      ggplot2::theme(
        plot.background = element_rect(fill = "#222222"),
        text = element_text(color = "white"),
        strip.text = element_text(color = "white"),
        axis.title.y = element_text(size = 20),
        axis.title.x = element_text(size = 20)
      )
  })

}
