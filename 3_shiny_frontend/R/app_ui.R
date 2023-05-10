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
      navbarPage(theme=shinytheme("superhero"),
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
                               leafletOutput("map", height="600px"),
                               DTOutput("user_location")
               ),
               column(width = 4,
                         plotOutput('user_input_plot',  height = "800px"),
               ))
               # start page ###############################################################
      ),
      tabPanel(title = "Daten darstellen & beschreiben",
               id    = "visualizeTab",
               value = "visualizeTab",
               icon  = icon("chart-column"),
        # make species plot start ############################################################'
        fluidRow(column(3,
                        selectInput('select_species', 'Baumart', choices = NULL, multiple = TRUE),
                        p(textOutput("selected_species_control"))
        ), column(width = 9,
                  h3(textOutput("select_species")),
                  plotOutput('species_plot',  height = "800px"),
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
