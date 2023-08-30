#' The application User-Interface
#'
#' @param request Internal parameter for `{shiny}`.
#'     DO NOT REMOVE.
#' @import shiny
#' @import shinythemes
#' @import markdown
#' @import bslib
#' @noRd
app_ui <- function(request) {
  tagList(
    # Leave this function for adding external resources
    golem_add_external_resources(),
    tags$head(HTML(read_file("inst/app/www/tracker.js"))),
    waiter::use_waiter(),
    bslib::page_navbar(nav_item(tags$img(src = "assets/logo.png", height = "40vh")),
                       nav_spacer(),
               title = tags$b("Treeful"),
               id = "mainNavbar",
               theme = bs_theme(version = 5, bootswatch = "lumen", primary = "#6e944eff", secondary = "#deeed4ff",
                                fg = "#2b2b40ff", warning = "#c65534c5", bg = "#fff",
                                danger = "#c75634ff"
                                ), window_title = "Treeful",
               sidebar = bslib::sidebar(id = "mainsidebar",
                                 class = "fw-bold font-monospace",
                                 selectInput('select_future', 'Jahrzehnt', choices = future_dates$year, multiple = F, selected = "2050"),
                                 selectInput('select_scenario', 'Szenario Klimaprojektion', choices = c("Mittleres Szenario (RCP4.5)", "Worst-Case Szenario (RCP8.5)"),
                                             multiple = F, selected = "Mittleres Szenario (RCP4.5)")
                                 ),
      # start page ############################################################'
      bslib::nav_panel(title = "Intro",
                 value = "settingTab",
                 fluidRow(
                   column(width = 6,
                          htmltools::includeMarkdown(file.path("inst", "app", "www", "intro.md")),
                          shiny::img(src = "assets/bmbf.jpg", width = "200vw", align = "center"),
                          includeHTML("inst/app/www/optout.html")

                   ),
                   column(width = 6,
                          leafletOutput("map", height="600px"),
                          shiny::br(),
                          actionButton(inputId = "nextpage", label = "Baumranking erkunden")
                 )
                 # column(width = 4,
                 #
                 #        DTOutput("user_location", fill = FALSE)
                 # )
                 )
                 # start page ###############################################################
        ),
      bslib::nav_panel(title = "🌳 Klimahüllen",
                 value = "visualizeTab",
                 fluidRow(
                   h2("Klimahüllen erstellen"),
                   htmltools::includeMarkdown(file.path("inst", "app", "www", "data_explorer.md")),
                   selectInput('select_species', 'Baumart', choices = NULL, multiple = F, width = "95vw"),
                      column(3,
                             #selectInput('select_species', 'Baumart', choices = NULL, multiple = F),
                             #p(textOutput("selected_species_control")),
                             # p(textOutput("selected_species_descr")),
                             # uiOutput("selected_species_wiki"),
                             # uiOutput("selected_species_gbif"),
                             # uiOutput("selected_species_img"),
                             uiOutput("explorer_card"),
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
      bslib::nav_panel(title = "📊 Steckbriefe",
                       value = "ranking",
                       p("Diese Baumarten sind die Top-10 für deinen Standort in der gewählten Klimaprojektion. Unser Ranking bezieht sich nur auf
                         klimatische Verhältnisse. Ob die Baumart zum Boden passt, giftig oder invasiv ist steht in den Steckbriefen und Links,
                         sollte jedoch selbst recherchiert werden. Keine Gewähr für fehlende Angaben.
                         "),
                       uiOutput("cards"),
      ),
      bslib::nav_panel(title = "🔎 Datenquellen",
                       value = "sources",
                       fluidRow(
                         column(width = 6,
                                htmltools::includeMarkdown(file.path("inst", "app", "www", "outro.md"))
                         ))
                       ),
      nav_spacer(),
      nav_item(tags$a("Github", href = "https://github.com/3ful/treeful"))
      ),
    tags$script(HTML(read_file("inst/app/www/eventracker.js"))),
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
  add_resource_path(
    'assets', app_sys('app/assets')
  )
  add_resource_path(
    'profiles', app_sys("app/tree_profiles")
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
