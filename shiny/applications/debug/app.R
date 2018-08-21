ui <- shiny::fluidPage(
  shiny::titlePanel("arrrrrRRg!"),
  shiny::sidebarLayout(
    shiny::sidebarPanel(
      shiny::textInput("code", "R code:"),
      shiny::actionButton("go", "Evaluate")),
    shiny::mainPanel(
      shiny::verbatimTextOutput("code_as_used"),
      shiny::verbatimTextOutput("result"))))


evaluate_to_str <- function(str) {
  res <- tryCatch(
    eval(parse(text = str), .GlobalEnv),
    error = identity)
  capture.output(res)
}


server <- function(input, output, session) {
  shiny::observeEvent(
    input$go, {
      shiny::isolate({
        code <- input$code
        if (nzchar(code)) {
          result <- evaluate_to_str(code)
          output$code_as_used <- shiny::renderText(paste0("R> ", code))
          output$result <- shiny::renderText(paste(result, collapse = "\n"))
        } else {
          output$code_as_used <- NULL
          output$result <- NULL
        }
      })
    })
}

shiny::shinyApp(ui = ui, server = server)
