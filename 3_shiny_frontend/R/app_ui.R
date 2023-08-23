#' The application User-Interface
#'
#' @param request Internal parameter for `{shiny}`.
#'     DO NOT REMOVE.
#' @import shiny
#' @import shinythemes
#' @noRd
app_ui <- function(request) {
  tagList(
    # Leave this function for adding external resources
    golem_add_external_resources(),
    # Your application UI logic
    fluidPage(
      navbarPage(theme=shinytheme("darkly"),
                 title = tags$b("Treeful"),
                 windowTitle = "Treeful",
                 id = "mainNavbar",
      # start page ############################################################'
      tabPanel(title = "Standort wählen",
               id    = "settingTab",
               value = "settingTab",
               icon  = icon("right-to-bracket"),
               fluidRow(
                 column(width = 4,
                        includeMarkdown(file.path("inst", "app", "www", "intro.md"))
                 ),
                 column(width = 4,
                               leafletOutput("map", height="600px")
               ),
               column(width = 4,
                      DTOutput("user_location", fill = FALSE)
               ))
               # start page ###############################################################
      ),
      tabPanel(title = "Data Explorer",
               id    = "visualizeTab",
               value = "visualizeTab",
               icon  = icon("chart-column"),

               fluidRow(
                 h2("Klimahüllen erstellen"),
                    p("Für jeweils eine Baumart können zwei Variablen zusammen dargestellt werden. Daraus ergeben sich zweidimensionale Klimahüllen,
                      eine Art Wohlfühlzone der Baumart."),
                    column(3,
                           #selectInput('select_species', 'Baumart', choices = NULL, multiple = F),
                           #p(textOutput("selected_species_control")),
                           selectInput('select_species', 'Baumart', choices = NULL, multiple = F),
                           p(textOutput("selected_species_descr")),
                           p(uiOutput("selected_species_img")),
                           p(textOutput("selected_species_control"))
                    ), column(width = 9,
                              shiny::fluidRow(
                                column(width = 6,
                                  selectInput('select_biovar1', 'Bioklimatische Variable X', choices = biovars$biovars, multiple = F, selected = "BIO01"),
                                ),
                                column(width = 6,
                                  selectInput('select_biovar2', 'Bioklimatische Variable Y', choices = biovars$biovars, multiple = F, selected = "BIO12"))
                                ),
                              #h3(textOutput("select_species")),
                              plotOutput('species_plot',  height = "100vh", width = "100%")
                    )),
               fluidRow(
                 h2("Bodenbedingungen abgleichen"),
                 p("Neben klimatischen Bedingungen ist auch der Boden entscheidend für einen Baum."),
                 column(3),
                 column(width = 9,
                           shiny::fluidRow(
                             column(width = 6,
                                    selectInput('select_soilvar1', 'Boden-Variable X', choices = soil_vars$soilvars, multiple = F, selected = "STU_EU_DEPTH_ROOTS"),
                             ),
                             column(width = 6,
                                    selectInput('select_soilvar2', 'Boden-Variable Y', choices = soil_vars$soilvars, multiple = F, selected = "STU_EU_T_CLAY"))
                           ),
                           #h3(textOutput("select_species")),
                           plotOutput('soil_plot',  height = "90vh", width = "100%")
                 ))
        # make species plot end ###############################################################
      )
    ))
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
