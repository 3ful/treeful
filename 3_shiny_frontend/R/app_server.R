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
Sys.setenv("POSTGRES_PW" = read_lines("/run/secrets/postgres_pw"))
Sys.setenv("POSTGRES_HOST" = read_lines("/run/secrets/postgres_host"))
Sys.setenv("POSTGRES_DB" = "treeful-test")


#Sys.setlocale("LC_TIME","de_DE.UTF-8")

app_server <- function(input, output, session) {

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

  output$user_location <- DT::renderDT(user_climate_long(), server = FALSE)

  # trees_quantiles <- DBI::dbGetQuery(backend_con, paste0("SELECT * FROM trees_quantiles"))
  # trees_quantiles <- tidyr::pivot_longer(trees_quantiles, cols = dplyr::ends_with(c("_val"))) %>%
  #   dplyr::select(dplyr::everything(), -dplyr::ends_with("quant"), -unpack, "bio01_quant") %>%
  #   dplyr::rename(quart = bio01_quant) %>%
  #   dplyr::mutate(name = toupper(stringr::str_remove(name, "_val")))


  updateSelectInput(session, "select_species", choices = species$latin_name, selected = "Sorbus torminalis")


  tree_occurrence <- reactive({
    #waiter <- waiter::Waiter$new(id = "species_plot")
    #waiter$show()
    #on.exit(waiter$hide())
    DBI::dbGetQuery(backend_con, paste0(
      "SELECT * FROM tree_dbs WHERE master_list_name ='", input$select_species, "';"))
  }) %>% bindCache(Sys.Date(), input$select_species)

  output$selected_species_control <- renderText({ paste0(nrow(tree_occurrence()), " Baumstandorte gefunden") })

  output$selected_species_descr <- renderText({ dplyr::filter(species, latin_name == input$select_species)$descr_de })
  output$selected_species_wiki <- renderUI({
    tags$a(paste0(dplyr::filter(species, latin_name == input$select_species)$latin_name, " bei Wikipedia"),
           href = dplyr::filter(species, latin_name == input$select_species)$url,
           target = "_blank")
    })

  output$selected_species_gbif <- renderUI({
    tags$a(paste0(dplyr::filter(species, latin_name == input$select_species)$latin_name, " bei GBIF"),
           href = paste0("https://www.gbif.org/species/", dplyr::filter(species, latin_name == input$select_species)$gbif_taxo_id),
                         target = "_blank")
  })

  output$selected_species_img <- renderUI({
    tags$a(
      tags$img(src = paste0("https://", dplyr::filter(species, latin_name == input$select_species)$image_url)),
      href = dplyr::filter(species, latin_name == input$select_species)$url,
      target = "_blank"
    )
  })

  lab_md <- c("Dein Standort **1979-2018**", "Dein Standort **2050**")

  user_x <- reactive({
    dplyr::filter(biovars, descr_de == input$select_biovar1[1])
  })
  user_y <- reactive({
    dplyr::filter(biovars, descr_de == input$select_biovar2[1])
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
  })
  #%>% bindCache(user_x(), user_y(), input$select_species)

  output$species_plot <- renderPlot({
    validate(
      need(input$map_click, 'Bitte Standort auf der Karte wählen!')
    )
    temp_species_plot() +
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
    dplyr::filter(soil_vars, descr_de == input$select_soilvar1[1])
  })
  user_soil_y <- reactive({
    dplyr::filter(soil_vars, descr_de == input$select_soilvar2[1])
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
  })
  #%>% bindCache(user_soil_x(), user_soil_y(), input$select_species)


  output$soil_plot <- renderPlot({
    validate(
      need(input$map_click, 'Bitte Standort auf der Karte wählen!')
    )
    temp_soil_plot() +

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
