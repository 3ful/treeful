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

shinyOptions(cache = cachem::cache_mem(max_size = 500e6))

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



#Sys.setlocale("LC_TIME","de_DE.UTF-8")

app_server <- function(input, output, session) {
  backend_con <- DBI::dbConnect(RPostgres::Postgres(),
                                dbname = "treeful-test",
                                host= "192.168.178.148",
                                port="5432",
                                user="postgres",
                                password="mysecretpassword")

  species <- DBI::dbGetQuery(backend_con, paste0("SELECT * FROM tree_master_list")) %>%
    dplyr::arrange(latin_name)

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

  get_biolayer <- function(band = 1, layer = "past", map_point = map_point()) {
    biovar <- RPostgreSQL::dbGetQuery(backend_con,make_query(map_point = map_point, layer = layer, band = band))$biovar
    return(biovar)
  }

  user_climate_wide <- reactive({
    req(input$map_click)

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

  # trees_quantiles <- DBI::dbGetQuery(backend_con, paste0("SELECT * FROM trees_quantiles"))
  # trees_quantiles <- tidyr::pivot_longer(trees_quantiles, cols = dplyr::ends_with(c("_val"))) %>%
  #   dplyr::select(dplyr::everything(), -dplyr::ends_with("quant"), -unpack, "bio01_quant") %>%
  #   dplyr::rename(quart = bio01_quant) %>%
  #   dplyr::mutate(name = toupper(stringr::str_remove(name, "_val")))


  updateSelectInput(session, "select_species", choices = species$latin_name, selected = "Sorbus torminalis")


  tree_occurrence <- reactive(
    DBI::dbGetQuery(backend_con, paste0(
      "SELECT * FROM tree_dbs WHERE master_list_name ='", input$select_species, "';"))
  ) %>% bindCache(Sys.Date(), input$select_species)

  output$selected_species_control <- renderText({ paste0(nrow(tree_occurrence()), " Baumstandorte gefunden") })

  output$selected_species_descr <- renderText({ dplyr::filter(species, latin_name == input$select_species)$descr_de })
  output$selected_species_img <- renderUI({
    tags$img(src = paste0("https://", dplyr::filter(species, latin_name == input$select_species)$image_url))
  })

  lab_md <- c("Dein Standort **1979-2018**", "Dein Standort **2050**")

  user_x <- reactive({
    dplyr::filter(biovars, biovars == input$select_biovar1[1])
  })
  user_y <- reactive({
    dplyr::filter(biovars, biovars == input$select_biovar2[1])
  })


  temp_species_plot <- reactive({
    ggplot2::ggplot(data = dplyr::filter(user_climate_wide(), layer %in% c("past", "future"))) +
    ggplot2::geom_point(data = tree_occurrence(), ggplot2::aes(x = .data[[user_x()$biovars]],
                            y = .data[[user_y()$biovars]], color = db),
                        alpha = 0.1, stroke = 0) +
    #geom_hex(aes(x = bio12_copernicus_1979_2018, y = bio01_copernicus_1979_2018), bins = 70) +
    #stat_density_2d(aes(x = bio12_copernicus_1979_2018, y = bio01_copernicus_1979_2018, fill = ..level..), geom = "polygon", colour="white") +
    scale_color_paletteer_d("wesanderson::Royal1") +
    #ggplot2::facet_wrap(~master_list_name) +
    hrbrthemes::theme_ipsum() +
    ggplot2::labs(title = paste0(user_x()$descr_de, " und ",
                                 user_y()$descr_de),
                  x = user_x()$descr_de,
                  y = user_y()$descr_de,
         subtitle = paste0("")) +
      ggplot2::theme(
        plot.background = element_rect(fill = "#222222"),
        text = element_text(color = "white"),
        strip.text = element_text(color = "white"),
        axis.title.y = element_text(size = 20),
        axis.title.x = element_text(size = 20)
        )
  }) %>% bindCache(user_x(), user_y(), input$select_species)

  output$species_plot <- renderPlot({temp_species_plot() +

    ggplot2::geom_point(ggplot2::aes(x = .data[[user_x()$biovars]],
                                     y = .data[[user_y()$biovars]]),
                        color = "steelblue", size = 4) +
    ggtext::geom_richtext(aes(x = .data[[user_x()$biovars]],
                              y = .data[[user_y()$biovars]], label = lab_md),
                          stat = "unique", angle = 30,
                          color = "white", fill = "steelblue",
                          label.color = NA, hjust = 0, vjust = 0,
                          family = "Playfair Display")
  })


  user_soil_x <- reactive({
    dplyr::filter(soil_vars, soilvars == input$select_soilvar1[1])
  })
  user_soil_y <- reactive({
    dplyr::filter(soil_vars, soilvars == input$select_soilvar2[1])
  })

  temp_soil_plot <- reactive({
    ggplot2::ggplot(data = dplyr::filter(user_climate_wide(), layer %in% c("soil"))) +
      ggplot2::geom_point(data = tree_occurrence(), ggplot2::aes(x = .data[[user_soil_x()$soilvars]],
                                       y = .data[[user_soil_y()$soilvars]], color = db),
                          alpha = 0.1, stroke = 0) +
      scale_color_paletteer_d("wesanderson::Royal1") +
      hrbrthemes::theme_ipsum() +
      ggplot2::labs(title = paste0(user_soil_x()$descr_de, " und ",
                                   user_soil_y()$descr_de),
                    x = user_soil_x()$descr_de,
                    y = user_soil_y()$descr_de,
                    subtitle = paste0("")) +
      ggplot2::theme(
        plot.background = element_rect(fill = "#222222"),
        text = element_text(color = "white"),
        strip.text = element_text(color = "white"),
        axis.title.y = element_text(size = 20),
        axis.title.x = element_text(size = 20)
      )
  }) %>% bindCache(user_soil_x(), user_soil_y(), input$select_species)


  output$soil_plot <- renderPlot({temp_soil_plot() +

        ggplot2::geom_point(ggplot2::aes(x = .data[[user_soil_x()$soilvars]],
                                         y = .data[[user_soil_y()$soilvars]]),
                            color = "darkolivegreen4", size = 4) +
        ggtext::geom_richtext(aes(x = .data[[user_soil_x()$soilvars]],
                                  y = .data[[user_soil_y()$soilvars]], label = "Bodenwerte an deinem Standort"),
                              stat = "unique", angle = 30,
                              color = "white", fill = "steelblue",
                              label.color = NA, hjust = 0, vjust = 0,
                              family = "Playfair Display")
    })
}
