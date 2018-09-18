ui <- shiny::fluidPage(
  shiny::h2("Host"),
  shiny::verbatimTextOutput("host"),
  shiny::h2("Environment variables"),
  shiny::verbatimTextOutput("envvars"),
  shiny::h2("Session"),
  shiny::verbatimTextOutput("session"),
  shiny::h2("Write to log"),
  shiny::textInput("log_value", ""),
  shiny::actionButton("log_it", "Send to log"))

server <- function(input, output, session) {
  output$host <- shiny::renderText(Sys.info()[["nodename"]])
  output$envvars <- shiny::renderPrint(Sys.getenv())
  output$session <- shiny::renderPrint(sessionInfo())
  shiny::observeEvent(
    input$log_it,
    message(input$log_value))
}

shiny::shinyApp(ui = ui, server = server)
