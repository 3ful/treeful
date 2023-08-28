#' The application User-Interface
#'
#' @param request Internal parameter for `{shiny}`.
#'     DO NOT REMOVE.
#' @import shiny
#' @import shinythemes
#' @import markdown
#' @noRd
app_ui <- function(request) {
  tagList(
    # Leave this function for adding external resources
    golem_add_external_resources(),
    # Your application UI logic
    fluidPage(
      tags$head(HTML(read_file("inst/app/www/tracker.js"))),
      waiter::use_waiter(),
      navbarPage(theme=shinytheme("darkly"),
                 title = tags$b("Treeful"),
                 windowTitle = "Treeful",
                 id = "mainNavbar",
      tabsetPanel(id = "tabs", type = "pills",
      # start page ############################################################'
        tabPanel(title = "🌍 Intro",
                 id    = "settingTab",
                 value = "settingTab",
                 fluidRow(
                   column(width = 4,
                          htmltools::includeMarkdown(file.path("inst", "app", "www", "intro.md")),
                          includeHTML("inst/app/www/optout.html")
                   ),
                   column(width = 4,
                                 leafletOutput("map", height="600px"),
                          actionButton(inputId = "nextpage", label = "Bäume erkkunden")
                 ),
                 column(width = 4,
                        selectInput('select_future', 'Jahrzehnt', choices = future_dates$year, multiple = F, selected = "2050"),
                        selectInput('select_scenario', 'Szenario Klimaprojektion', choices = c("Mittleres Szenario (RCP4.5)", "Worst-Case Szenario (RCP8.5)"),
                                    multiple = F, selected = "Mittleres Szenario (RCP4.5)"),
                        DTOutput("user_location", fill = FALSE)
                 ))
                 # start page ###############################################################
        ),
        tabPanel(title = "Ranking",
                 id    = "ranking",
                 value = "ranking",
                 fluidRow(
                   column(width = 2,
                   ),
                   column(width = 10,
                          DTOutput("ranking", fill = FALSE))
                  )
                 ),
        tabPanel(title = "🌳 Klimahüllen",
                 id    = "visualizeTab",
                 value = "visualizeTab",
                 fluidRow(
                   h2("Klimahüllen erstellen"),
                   p("Für eine Baumart siehst du zwei Variablen. Daraus ergeben sich zweidimensionale Klimahüllen,
                        eine Art Wohlfühlzone der Baumart."),
                   selectInput('select_species', 'Baumart', choices = NULL, multiple = F),
                      column(3,
                             #selectInput('select_species', 'Baumart', choices = NULL, multiple = F),
                             #p(textOutput("selected_species_control")),
                             p(textOutput("selected_species_descr")),
                             uiOutput("selected_species_wiki"),
                             uiOutput("selected_species_gbif"),
                             uiOutput("selected_species_img"),
                             p(textOutput("selected_species_control"))
                      ), column(width = 9,
                                shiny::fluidRow(
                                  column(width = 6,
                                    selectInput('select_biovar1', 'Bioklimatische Variable X', choices = biovars$descr_de, multiple = F, selected = "Jahresdurchschnittstemperatur"),
                                  ),
                                  column(width = 6,
                                    selectInput('select_biovar2', 'Bioklimatische Variable Y', choices = biovars$descr_de, multiple = F, selected = "Jahresniederschlag"))
                                  ),
                                #h3(textOutput("select_species")),
                                plotOutput('species_plot',  height = "90vh", width = "100%")
                      )),
                 fluidRow(
                   h2("Bodenbedingungen abgleichen"),
                   p("Neben klimatischen Bedingungen ist auch der Boden entscheidend für einen Baum. Bodendaten von ESDAC. "),
                   column(3),
                   column(width = 9,
                             shiny::fluidRow(
                               column(width = 6,
                                      selectInput('select_soilvar1', 'Boden-Variable X', choices = soil_vars$descr_de, multiple = F, selected = "Wurzelverfügbare Tiefe cm"),
                               ),
                               column(width = 6,
                                      selectInput('select_soilvar2', 'Boden-Variable Y', choices = soil_vars$descr_de, multiple = F, selected = "Tonanteil % Unterboden"))
                             ),
                             #h3(textOutput("select_species")),
                             plotOutput('soil_plot',  height = "90vh", width = "100%")
                   ))
          # make species plot end ###############################################################
        ),
      tags$script(HTML(read_file("inst/app/www/eventracker.js"))),
      ))
  )
  )
}

#' Add external Resources to the Application
#'
#' This function is internally used to add external
#' resources inside the Shiny application.
#'
#' @import shiny
#' @importFrom golem add_resource_path activate_js favicon bundle_resources
#' @noRd
golem_add_external_resources <- function() {
  add_resource_path(
    "www",
    app_sys("app/www")
  )

  tags$head(
    favicon(),
    bundle_resources(
      path = app_sys("app/www"),
      app_title = "treeful"
    )
    # Add here other external resources
    # for example, you can add shinyalert::useShinyalert()
  )
}
