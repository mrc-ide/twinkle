## TODO:
##
## authentication
## parse the log names perhaps
## try and convince selectinput to render things nicely but that's a hassle

## <application directory name>-YYYMMDD-HHmmss-<port number or socket ID>.log

## test-shiny-20180915-152819-43631.log
## hello-shiny-20180915-155656-46495.log

passwordfile <- Sys.getenv("APACHE_PASSWORD_FILE", "/twinkle/apache_auth/users")
groupfile <- Sys.getenv("APACHE_PASSWORD_FILE", "/twinkle/apache_auth/groups")
vault_env_file <- Sys.getenv("VAULT_ENV_FILE", "/twinkle/.vault")
target_dir <- Sys.getenv("SHINY_LOG_DIR", "/twinkle/logs")

DEFAULT_MAX_AGE <- 3600

list_files <- function(path, cutoff = 600) {
  files <- dir(path, full.names = TRUE)
  mtime <- file.info(files, extra_cols = FALSE)$mtime
  age <- as.numeric(Sys.time() - mtime, "secs")
  i <- order(age)
  i <- i[age[i] <= cutoff]
  files <- files[i]
  mtime <- mtime[i]
  age <- age[i]
  data.frame(name = basename(files),
             full = files,
             mtime = mtime,
             age = age)
}


ui <- shiny::fluidPage(
  shiny::h2("Shiny logs"),
  shiny::sidebarLayout(
    shiny::sidebarPanel(
      shiny::h3("Log files"),
      shiny::numericInput("max_age", "Maximum age (seconds)", DEFAULT_MAX_AGE),
      shiny::selectInput("log_file_target", "Select log", character()),
      shiny::actionButton("go", "Go", class = "btn-primary"),
      shiny::actionButton("refresh", "Refresh", class = "btn-info"),
      shiny::actionButton("clear", "Clear", class = "btn-danger")),
    shiny::mainPanel(
      shiny::tabsetPanel(
        shiny::tabPanel(
          "Files",
          shiny::dataTableOutput("files"),
          value = "panel_file"),
        shiny::tabPanel(
          "Log content",
          shiny::verbatimTextOutput("log_contents"),
          value = "panel_contents"),
        id = "tabset"))))



read_string <- function(filename) {
  readChar(filename, file.size(filename))
}


server <- function(input, output, session) {
  target <- shiny::reactiveValues(
    data = NULL, logs = NULL)
  files <- shiny::reactiveValues(
    data = list_files(target_dir, DEFAULT_MAX_AGE))

  interval <- 1000

  shiny::observeEvent(
    input$refresh, {
      files$data <- list_files(target_dir, input$max_age)
      shiny::updateTabsetPanel(session, "tabset", "panel_file")
    })

  shiny::observe({
    shiny::updateSelectInput(session, "log_file_target",
                             choices = files$data$name)
    output$files <- shiny::renderDataTable(
      files$data[c("name", "age")])
  })

  shiny::observeEvent(
    input$go, {
      path <- file.path(target_dir, input$log_file_target)
      target$data <-
        shiny::reactiveFileReader(interval, session, path, read_string)
      shiny::updateTabsetPanel(session, "tabset", "panel_contents")
    })

  shiny::observeEvent(
    input$clear, {
      target$data <- NULL
    })

  shiny::observe(
    output$log_contents <- target$data
  )
}


shiny::shinyApp(ui = ui, server = server)
