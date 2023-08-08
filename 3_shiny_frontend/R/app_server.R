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
                              "BIO10", "BIO11", "BIO12", "BIO13", "BIO14", "BIO15", "BIO16", "BIO17", "BIO18", "BIO19")) %>%
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
  #on.exit(DBI::dbDisconnect(backend_con), add = TRUE)

  output$map <- renderLeaflet({leaflet()%>% addTiles()})

  observe({
    click <- input$map_click
    req(click)
    leafletProxy('map') %>% clearMarkers()
    leafletProxy('map')%>% addMarkers(lng = click$lng, lat = click$lat)

  })

  # cobble together query, used for user climate
  make_query <- function(map_point, layer = "", band = dplyr::filter(biovars, biovars == input$select_biovar)$rowid) {
    return(paste0("SELECT g.pt_geom, ST_Value(ST_Band(r.rast, ARRAY[", band, "]), g.pt_geom) AS biovar
      FROM public.", layer, " AS r
      INNER JOIN
      (SELECT ST_Transform(ST_SetSRID(ST_MakePoint(", map_point$lon, ",", map_point$lat, "), 4326),4326) As pt_geom) AS g
      ON r.rast && g.pt_geom;"))
  }

  # getting past and future for one biovar from one location
  get_user_climate <- function(connection = backend_con, lat = input$map_click$lat, lon = input$map_click$lng,
                               user_biovar = dplyr::filter(biovars, biovars == input$select_biovar)$rowid) {
    map_point <- sf::st_as_sf(tibble::tibble(lat = lat, lon = lon), coords = c("lon", "lat"), crs = 4326, remove =FALSE)

    #get past at map location
    bio_hist <- RPostgreSQL::dbGetQuery(backend_con,make_query(map_point, layer = "past", band = user_biovar)) %>%
      dplyr::select(-pt_geom, past = biovar)
    bio_future <- RPostgreSQL::dbGetQuery(backend_con,make_query(map_point, layer = "future", band = user_biovar)) %>%
      dplyr::select(-pt_geom, future = biovar)


    return(tibble::tibble(bio_future, bio_hist))
  }


  get_all_biovars <- function() {


  }

  user_climate1 <- reactive({
    req(input$map_click)
      get_user_climate(connection = backend_con, lat = input$map_click$lat, lon = input$map_click$lng,
                       user_biovar = dplyr::filter(biovars, biovars == input$select_single_biovar)$rowid[1])
    })

  user_climate2 <- reactive({
    tibble::tibble(
      get_user_climate(connection = backend_con, lat = input$map_click$lat, lon = input$map_click$lng,
                       user_biovar = dplyr::filter(biovars, biovars == input$select_biovar1)$rowid[1]) %>%
        dplyr::select(past1 = past, future1 = future),
      get_user_climate(connection = backend_con, lat = input$map_click$lat, lon = input$map_click$lng,
                       user_biovar = dplyr::filter(biovars, biovars == input$select_biovar2)$rowid[1]) %>%
        dplyr::select(past2 = past, future2 = future)
    )
  })
  output$user_location <- renderDT(user_climate1())

  #tree_db <- data.table::fread("data/tree_db.csv")
  species <- DBI::dbGetQuery(backend_con, paste0("SELECT DISTINCT master_list_name FROM tree_dbs"))
  trees_quantiles <- DBI::dbGetQuery(backend_con, paste0("SELECT * FROM trees_quantiles"))

  updateSelectInput(session, "select_species", choices = species$master_list_name, selected = "Sorbus torminalis")

  # tree_occurrence <- reactive(tree_db[master_list_name %in% c(input$select_species), ]
  # )
  #selection <- reactive(input$select_species)

  tree_occurrence <- reactive(
    DBI::dbGetQuery(backend_con, paste0(
      "SELECT * FROM tree_dbs WHERE master_list_name ='", input$select_species, "';"))
  )

  output$selected_species_control <- renderText({ paste0(nrow(tree_occurrence()), " Baumstandorte gefunden") })

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
    scale_fill_continuous(type = "viridis") +
    ggplot2::geom_point(data = user_climate2(), ggplot2::aes(x = past1, y = past2), color = "darkolivegreen4", size = 4) +
    ggplot2::geom_point(data = user_climate2(), ggplot2::aes(x = future1, y = future2), color = "darkolivegreen1", size = 4) +
        scale_color_paletteer_d("wesanderson::Royal1") +
    ggplot2::facet_wrap(~master_list_name) +
    hrbrthemes::theme_ipsum() +
    ggplot2::labs(title = paste0("Jahrestemperatur und Jahresniederschlag"),
         subtitle = paste0("")) +
      ggplot2::theme(plot.background = element_rect(fill = "black"),
          text = element_text(color = "white"),
          strip.text = element_text(color = "white"))
  })
  output$violin_plot <- renderPlot({
    ggplot2::ggplot(data = tree_occurrence(), ggplot2::aes(x = 1, y = .data[[dplyr::filter(biovars, biovars == input$select_single_biovar)$biovars]])) +
      geom_violin(width=1.4) +
      geom_boxplot(width=0.1, color="grey", alpha=0.2) +
      ggplot2::geom_point(data = user_climate1(), ggplot2::aes(x = 1, y = past), color = "darkolivegreen4", size = 4) +
      ggplot2::geom_point(data = user_climate1(), ggplot2::aes(x = 1, y = future), color = "darkolivegreen1", size = 4) +
      scale_color_paletteer_d("wesanderson::Royal1") +
      theme_ipsum() +
      theme(
        legend.position="none",
        plot.title = element_text(size=11)
      ) +
      ggtitle(paste0(input$select_species, " Violine um ein Boxplot. ")) +
      xlab("")
  })



}
