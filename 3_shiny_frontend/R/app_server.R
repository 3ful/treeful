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
#' @import bslib
#' @import ggtext
#' @noRd

# library(tidyverse)
# library(hrbrthemes)
# library(paletteer)
# library(leaflet)
# #library(sf)
# #library(raster)
# library(ggplot2)
# library(ggtext)

shinyOptions(cache = cachem::cache_mem(max_size = 500e6))
Sys.setenv("POSTGRES_PW" = read_lines("/run/secrets/postgres_pw"))
Sys.setenv("POSTGRES_HOST" = read_lines("/run/secrets/postgres_host"))
Sys.setenv("POSTGRES_DB" = "treeful-test")

# Sys.setlocale("LC_TIME","de_DE.UTF-8")

app_server <- function(input, output, session) {
  # bs_themer()


  #################### Processing of User location, Map, leaflet #######################

  output$map <- renderLeaflet({
    leaflet() %>%
      addTiles() %>%
      leaflet.extras::addSearchOSM() %>%
      leaflet::setView(lat = 48.17, lng = 17.49, zoom = 4) %>%
      addMarkers(lat = 51.3069, lng = 11.0012)
  })

  observe({
    click <- input$map_click
    req(click)
    leafletProxy("map") %>% clearMarkers()
    leafletProxy("map") %>% addMarkers(lng = click$lng, lat = click$lat)
  })

  observeEvent(input$nextpage, {
    validate(
      need(input$map_click, "Bitte Standort auf der Karte wählen!")
    )
    updateTabsetPanel(session = session, inputId = "mainNavbar", selected = "visualizeTab")
  })

  observeEvent(input$lastpage, {
    validate(
      need(input$map_click, "Bitte Standort auf der Karte wählen!")
    )
    updateTabsetPanel(session = session, inputId = "mainNavbar", selected = "ranking")
  })

  # construct user point as sf
  map_point <-
    reactive({
      sf::st_as_sf(tibble::tibble(lat = input$map_click$lat, lon = input$map_click$lng), coords = c("lon", "lat"), crs = 4326, remove = FALSE)
    })

  user_climate_wide <- reactive({
    req(input$map_click)
    req(map_point())

    bio_extract(
      map_point. = map_point(), experiment = dplyr::filter(experiment, label == input$select_scenario)$id,
      future_date = dplyr::filter(future_dates, year == input$select_future)$index
    )
  })

  # output$user_location <- DT::renderDT(user_climate_wide() %>% tidyr::pivot_longer(cols = where(is.numeric)) %>% filter(!is.na(value)), server = FALSE)

  tree_occurrence <- reactive({
    # waiter <- waiter::Waiter$new(id = "species_plot")
    # waiter$show()
    # on.exit(waiter$hide())
    DBI::dbGetQuery(backend_con, paste0(
      "SELECT * FROM tree_dbs WHERE master_list_name ='", input$select_species, "';"
    ))
  }) %>% bindCache(Sys.Date(), input$select_species)


  ################### Ranking ################


  ranking <- reactive({
    req(user_climate_wide())
    purrr::map_dfr(names(biovars_c), closest_match, user_climate = user_climate_wide()) %>%
      filter(bioclim_variable %in% c(
        "BIO01", "BIO05", "BIO06", "BIO08", "BIO09", "BIO10", "BIO11", "BIO12", "BIO13",
        "BIO14", "BIO16", "BIO17", "BIO18", "BIO19"
      )) %>%
      group_by(species) %>%
      mutate(bioclim_n = n()) %>%
      ungroup() %>%
      mutate(score = 100 - centile) %>%
      group_by(species) %>%
      summarise(summed_score = sum(score)) %>%
      arrange(desc(summed_score)) %>%
      slice(1:10) %>%
      dplyr::left_join(species, by = c("species" = "latin_name")) %>%
      rowid_to_column()
  })


  ################# UI-linked reactives ####################

  updateSelectInput(session, "select_species", choices = species$latin_name, selected = "Sorbus torminalis")

  output$selected_species_control <- renderText({
    paste0(nrow(tree_occurrence()), " Baumstandorte gefunden")
  })

  output$explorer_card <- renderUI({
    select_steckbrief <- dplyr::filter(species, latin_name == input$select_species) %>%
      dplyr::select(
        tree_image = image_url, tree_descr = latin_name,
        gbif = gbif_taxo_id, wikipedia = url
      )

    make_explorer_cards(
      tree_descr = select_steckbrief$tree_descr, tree_image = select_steckbrief$tree_image,
      gbif = select_steckbrief$gbif, wikipedia = select_steckbrief$wikipedia
    )
  })



  ################### Make Steckbriefe ###########################
  output$cards <- renderUI(
    purrr::pmap(
      .l = dplyr::select(ranking(),
        tree_index = rowid, tree_image = image_url, tree_descr = species,
        gbif = gbif_taxo_id, wikipedia = url, score = summed_score, water = water_body
      ),
      .f = make_cards
    )
  )
  #
  #   output$cards_even <- renderUI(
  #     purrr::map2(.x = ranking()$image_url[c(2,4,6,8,10)], .y = str_replace_all(ranking()$species[c(2,4,6,8,10)], "\\s", "_"), make_cards)
  #
  #   )




  ################### Plotting Charts, labels, Reactives on that########################


  lab_md <- c("Dein Standort **1979-2018**", "Dein Standort **2050**")

  user_x <- reactive({
    dplyr::filter(biovars, descr_de == input$select_biovar1[1])
  })
  user_y <- reactive({
    dplyr::filter(biovars, descr_de == input$select_biovar2[1])
  })


  temp_species_plot <- reactive({
    ggplot2::ggplot(data = dplyr::filter(user_climate_wide(), dimension %in% c("past", "future"))) +
      ggplot2::geom_point(
        data = tree_occurrence(), ggplot2::aes(
          x = .data[[user_x()$biovars]],
          y = .data[[user_y()$biovars]]
        ),
        color = col_warning,
        alpha = 0.1, stroke = 0
      ) +
      # scale_color_paletteer_d("wesanderson::Royal1") +
      # ggplot2::facet_wrap(~master_list_name) +
      hrbrthemes::theme_ipsum() +
      labs(
        title = paste0(
          user_x()$descr_de, " und ",
          user_y()$descr_de
        ),
        x = user_x()$descr_de,
        y = user_y()$descr_de,
        subtitle = paste0("Habitat von ", input$select_species, " und dein Standort im Vergleich")
      ) +
      ggplot2::theme(
        plot.background = element_rect(fill = col_fg),
        text = element_text(color = "white"),
        plot.title = element_text(size = 24),
        plot.subtitle = element_text(size = 20),
        strip.text = element_text(color = "white"),
        axis.title.y = element_text(size = 18),
        axis.title.x = element_text(size = 18),
        axis.text.x = element_text(size = 14, face = "bold", color = "white"),
        axis.text.y = element_text(size = 14, face = "bold", color = "white"),
        legend.position = "bottom"
      )
  })
  # %>% bindCache(user_x(), user_y(), input$select_species)

  output$species_plot <- renderPlot({
    validate(
      need(input$map_click, "Bitte Standort auf der Karte wählen!")
    )
    temp_species_plot() +
      ggplot2::geom_point(
        ggplot2::aes(
          x = .data[[user_x()$biovars]],
          y = .data[[user_y()$biovars]]
        ),
        color = col_primary, size = 4
      ) +
      ggtext::geom_richtext(
        aes(
          x = .data[[user_x()$biovars]],
          y = .data[[user_y()$biovars]],
          label = c("Dein Standort **1979-2018**", paste0("Dein Standort **", input$select_future, "**"))
        ),
        stat = "unique", angle = 30,
        color = col_fg, fill = col_secondary,
        label.color = NA, hjust = 0, vjust = 0,
        family = "Playfair Display"
      )
  })


  user_soil_x <- reactive({
    dplyr::filter(soil_vars, descr_de == input$select_soilvar1[1])
  })
  user_soil_y <- reactive({
    dplyr::filter(soil_vars, descr_de == input$select_soilvar2[1])
  })

  temp_soil_plot <- reactive({
    ggplot2::ggplot(data = dplyr::filter(user_climate_wide(), dimension %in% c("soil"))) +
      ggplot2::geom_point(
        data = tree_occurrence(), ggplot2::aes(
          x = .data[[user_soil_x()$soilvars]],
          y = .data[[user_soil_y()$soilvars]]
        ),
        alpha = 0.1, stroke = 0, color = col_warning
      ) +
      # scale_color_paletteer_d("wesanderson::Royal1") +
      hrbrthemes::theme_ipsum() +
      ggplot2::labs(
        title = paste0(
          user_soil_x()$descr_de, " und ",
          user_soil_y()$descr_de
        ),
        x = user_soil_x()$descr_de,
        y = user_soil_y()$descr_de,
        subtitle = paste0("")
      ) +
      ggplot2::theme(
        plot.background = element_rect(fill = col_fg),
        text = element_text(color = "white"),
        plot.title = element_text(size = 24),
        plot.subtitle = element_text(size = 20),
        strip.text = element_text(color = "white"),
        axis.title.y = element_text(size = 18),
        axis.title.x = element_text(size = 18),
        axis.text.x = element_text(size = 14, face = "bold", color = "white"),
        axis.text.y = element_text(size = 14, face = "bold", color = "white"),
        legend.position = "bottom"
      )
  })
  # %>% bindCache(user_soil_x(), user_soil_y(), input$select_species)


  output$soil_plot <- renderPlot({
    validate(
      need(input$map_click, "Bitte Standort auf der Karte wählen!")
    )
    temp_soil_plot() +

      ggplot2::geom_point(
        ggplot2::aes(
          x = .data[[user_soil_x()$soilvars]],
          y = .data[[user_soil_y()$soilvars]]
        ),
        color = col_primary, size = 4
      ) +
      ggtext::geom_richtext(
        aes(
          x = .data[[user_soil_x()$soilvars]],
          y = .data[[user_soil_y()$soilvars]], label = "Bodenwerte an deinem Standort"
        ),
        stat = "unique", angle = 30,
        color = col_fg, fill = col_secondary,
        label.color = NA, hjust = 0, vjust = 0,
        family = "Playfair Display"
      )
  })
}
