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

  conn <- DBI::dbConnect(RPostgres::Postgres(),
                        dbname = "treeful-test",
                        host= "192.168.178.148",
                        port="5432",
                        user="postgres",
                        password="mysecretpassword")
  on.exit(DBI::dbDisconnect(con), add = TRUE)

  output$map <- renderLeaflet({leaflet()%>% addTiles()})

  observe({
    click <- input$map_click
    req(click)
    leafletProxy('map') %>% clearMarkers()
    leafletProxy('map')%>% addMarkers(lng = click$lng, lat = click$lat)

  })

  ##################### Function to Get past climate ##################
  getpastclimate <- function(source = "copernicus", bioclim = "bio01") {
    if (source == "copernicus") {
      # Get bioclimate data from copernicus. Download bioclimate file with login at https://cds.climate.copernicus.eu/

      bio_path <- dplyr::case_when(bioclim == "bio01" ~ "BIO01",
                            bioclim == "bio12" ~ "BIO12"
      )

      bio_raster <- raster::raster(paste0("data-raw/copernicus/", bio_path, "_era5-to-1km_1979-2018-mean_v1.0.nc"))
      # convert bioclim as per copernicus documentation. for some reasone case_when does not work here.
      if (bioclim == "bio01") {bio_raster <- raster::calc(bio_raster, function(x) {x - 273.15})
      } else if (bioclim == "bio12") {bio_raster <- raster::calc(bio_raster, function(x) {x*3600*24*365*1000})}
    }
    return(bio_raster)
  }


  #################### Get Future Climate ##################
  # for now using climate projection model MPI-ESM1-2-LR and socio-econ pathway 245
  getfutureclimate <- function(source = "copernicus") {
    if (source == "copernicus") {
      future_raster_bio01 <- raster::stack("data-raw/copernicus/future/BIO01_hadgem2-cc_rcp45_r1i1p1_1960-2099-mean_v1.0.nc")$X2050.01.01
      future_raster_bio12 <- raster::stack("data-raw/copernicus/future/BIO12_hadgem2-cc_rcp45_r1i1p1_1960-2099-mean_v1.0.nc")$X2050.01.01

      future_raster_bio01 <- raster::calc(future_raster_bio01, function(x) {x - 273.15})
      future_raster_bio12 <- raster::calc(future_raster_bio12, function(x) {x*3600*24*365*1000})

      future_raster <- raster::stack(future_raster_bio01, future_raster_bio12)
      names(future_raster)[1] <- "bio01"
      names(future_raster)[2] <- "bio12"
    }
    return(future_raster)
  }



  #future_raster <- getfutureclimate(source = "copernicus")

  make_query <- function(map_point, layer = "", band = 1) {
    return(paste0("SELECT g.pt_geom, ST_Value(ST_Band(r.rast, ARRAY[", band, "]), g.pt_geom) AS biovar
      FROM public.", layer, " AS r
      INNER JOIN
      (SELECT ST_Transform(ST_SetSRID(ST_MakePoint(", map_point$lon, ",", map_point$lat, "), 4326),4326) As pt_geom) AS g
      ON r.rast && g.pt_geom;"))
  }

  get_user_climate <- function(con = conn, lat = input$map_click$lat, lon = input$map_click$lng) {
    map_point <- sf::st_as_sf(tibble(lat = lat, lon = lon), coords = c("lon", "lat"), crs = 4326, remove =FALSE)

    #get past at map location
    bio01_hist <- RPostgreSQL::dbGetQuery(con,make_query(map_point, layer = "pastbio01", band = 1))$biovar
    bio12_hist <- RPostgreSQL::dbGetQuery(con,make_query(map_point, layer = "pastbio12", band = 1))$biovar


    bio01_future <- RPostgreSQL::dbGetQuery(con,make_query(map_point, layer = "future", band = 1))$biovar
    bio12_future <-  RPostgreSQL::dbGetQuery(con,make_query(map_point, layer = "future", band = 2))$biovar

    return(tibble(bio01_future, bio12_future,
                  bio01_hist, bio12_hist
    ))
  }
  user_climate1 <- reactive({
    req(input$map_click)
    get_user_climate()

    })

  output$user_location <- renderDT(user_climate1())

  tree_db <- data.table::fread("data/tree_db.csv")
  species <- unique(tree_db$master_list_name)

  updateSelectInput(session, "select_species", choices = species, selected = "Sorbus torminalis")

  # tree_occurrence <- reactive(tree_db[master_list_name %in% c(input$select_species), ]
  # )
  #selection <- reactive(input$select_species)

  tree_occurrence <- reactive(
    DBI::dbGetQuery(conn, paste0(
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
    ggplot2::geom_point(aes(x = bio12_copernicus_1979_2018, y = bio01_copernicus_1979_2018, color = db), alpha = 0.1, lwd = 0) +
    ggplot2::geom_point(data = user_climate1(), aes(x = bio12_hist, y = bio01_hist), color = "darkolivegreen4", size = 4) +
    ggplot2::geom_point(data = user_climate1(), aes(x = bio12_future, y = bio01_future), color = "darkolivegreen", size = 4) +
    scale_color_paletteer_d("wesanderson::Royal1") +
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
