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
#' @noRd

# library(tidyverse)
# library(hrbrthemes)
# library(paletteer)
# library(leaflet)
# #library(sf)
# #library(raster)
library(ggplot2)
library(tibble)

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

  make_query <- function(map_point, layer = "", band = 1) {
    return(paste0("SELECT g.pt_geom, ST_Value(ST_Band(r.rast, ARRAY[", band, "]), g.pt_geom) AS biovar
      FROM public.", layer, " AS r
      INNER JOIN
      (SELECT ST_Transform(ST_SetSRID(ST_MakePoint(", map_point$lon, ",", map_point$lat, "), 4326),4326) As pt_geom) AS g
      ON r.rast && g.pt_geom;"))
  }

  get_user_climate <- function(connection = backend_con, lat = input$map_click$lat, lon = input$map_click$lng) {
    map_point <- sf::st_as_sf(tibble(lat = lat, lon = lon), coords = c("lon", "lat"), crs = 4326, remove =FALSE)

    #get past at map location
    bio01_hist <- RPostgreSQL::dbGetQuery(connection,make_query(map_point, layer = "pastbio01", band = 1))$biovar
    bio12_hist <- RPostgreSQL::dbGetQuery(connection,make_query(map_point, layer = "pastbio12", band = 1))$biovar


    bio01_future <- RPostgreSQL::dbGetQuery(connection,make_query(map_point, layer = "future", band = 1))$biovar
    bio12_future <-  RPostgreSQL::dbGetQuery(connection,make_query(map_point, layer = "future", band = 2))$biovar

    return(tibble(bio01_future, bio12_future,
                  bio01_hist, bio12_hist
    ))
  }
  user_climate1 <- reactive({
    req(input$map_click)
    get_user_climate()
    })

  output$user_location <- renderDT(user_climate1())

  #tree_db <- data.table::fread("data/tree_db.csv")
  species <- DBI::dbGetQuery(backend_con, paste0("SELECT DISTINCT master_list_name FROM tree_dbs"))

  updateSelectInput(session, "select_species", choices = species$master_list_name, selected = "Sorbus torminalis")

  # tree_occurrence <- reactive(tree_db[master_list_name %in% c(input$select_species), ]
  # )
  #selection <- reactive(input$select_species)

  tree_occurrence <- reactive(
    DBI::dbGetQuery(backend_con, paste0(
      "SELECT * FROM tree_dbs WHERE master_list_name ='", input$select_species, "';"))
  )

  output$selected_species_control <- renderText({ paste0(nrow(tree_occurrence()), " Baumstandorte gefunden") })

  output$user_input_plot <- renderPlot({
    ggplot2::ggplot(data = user_climate1()) +
      ggplot2::geom_point(aes(x = bio12_hist, y = bio01_hist), color = "blue") +
      ggplot2::geom_label(aes(x = bio12_hist, y = bio01_hist, label = "Klima 1979-2018")) +
      ggplot2::geom_point(aes(x = bio12_future, y = bio01_future), color = "darkred") +
      ggplot2::geom_label(aes(x = bio12_future, y = bio01_future, label = "Klima 2050")) +
      ggplot2::geom_segment(aes(x = bio12_hist, y = bio01_hist, xend = bio12_future, yend = bio01_future), color = "black") +
      hrbrthemes::theme_ipsum() +
      ggplot2::labs(title = paste0("Jahrestemperatur und Jahresniederschlag am gewählten Standort"),
           subtitle = paste0(""))
  })

  output$species_plot <- renderPlot({
    ggplot2::ggplot(data = tree_occurrence()) +
    #ggplot2::geom_point(aes(x = bio12_copernicus_1979_2018, y = bio01_copernicus_1979_2018, color = db), alpha = 0.1, lwd = 0) +
    #geom_bin2d(aes(x = bio12_copernicus_1979_2018, y = bio01_copernicus_1979_2018), bins = 70) +
    stat_density_2d(aes(x = bio12_copernicus_1979_2018, y = bio01_copernicus_1979_2018, fill = ..level..), geom = "polygon", colour="white") +
    scale_fill_continuous(type = "viridis") +
    ggplot2::geom_point(data = user_climate1(), aes(x = bio12_hist, y = bio01_hist), color = "darkolivegreen4", size = 4) +
    ggplot2::geom_point(data = user_climate1(), aes(x = bio12_future, y = bio01_future), color = "darkolivegreen", size = 4) +
    #scale_color_paletteer_d("wesanderson::Royal1") +
    ggplot2::facet_wrap(~master_list_name) +
    hrbrthemes::theme_ipsum() +
    ggplot2::labs(title = paste0("Jahrestemperatur und Jahresniederschlag"),
         subtitle = paste0("")) +
      ggplot2::theme(plot.background = element_rect(fill = "black"),
          text = element_text(color = "white"),
          strip.text = element_text(color = "white"))
  })
  # observeEvent(chronik_filtered(), {
  #   updateSelectInput(session, "county_timeline_option1", choices = unique(chronik_filtered()$county), selected = unique(chronik_filtered()$county))
  # })
}
