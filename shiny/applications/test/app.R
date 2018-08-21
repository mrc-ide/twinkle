ui <- shiny::fluidPage(
  shiny::h2("Host"),
  shiny::verbatimTextOutput("host"),
  shiny::h2("Environment variables"),
  shiny::verbatimTextOutput("envvars"),
  shiny::h2("Session"),
  shiny::verbatimTextOutput("session"))

server <- function(input, output, session) {
  output$host <- shiny::renderText(Sys.info()[["nodename"]])
  output$envvars <- shiny::renderPrint(Sys.getenv())
  output$session <- shiny::renderPrint(sessionInfo())
}

shiny::shinyApp(ui = ui, server = server)
