ui <- shiny::fluidPage(
  shiny::titlePanel("Hello shiny!"),
  shiny::sidebarLayout(
    shiny::sidebarPanel(
      shiny::sliderInput("n", "Number of obs", 10, 1000, 50)),
    shiny::mainPanel(
      shiny::plotOutput("plot"))))


server <- function(input, output, session) {
  output$plot <- shiny::renderPlot({
    hist(runif(input$n))
  })
}

shiny::shinyApp(ui = ui, server = server)
