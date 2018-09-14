passwordfile <- Sys.getenv("APACHE_PASSWORD_FILE", "/apache_auth/users")
groupfile <- Sys.getenv("APACHE_PASSWORD_FILE", "/apache_auth/groups")
vault_env_file <- Sys.getenv("VAULT_ENV_FILE", "/.vault")

ui <- shiny::fluidPage(
  shiny::titlePanel("User management"),
  shiny::sidebarLayout(
    shiny::sidebarPanel(
      twinkle::login_ui("login")),
    shiny::mainPanel(
      shiny::uiOutput("main"))))


server <- function(input, output, session) {
  Sys.unsetenv(c("VAULTR_AUTH_METHOD", "VAULTR_CACHE_DIR"))
  readRenviron(vault_env_file)

  auth <- shiny::callModule(twinkle::login_server, "login",
                            passwordfile, groupfile)

  shiny::observe({
    output$main <- shiny::renderUI(server_main_panel(auth$is_admin))
  })

  shiny::observeEvent(
    input$pw_set, {
      error_title <- "Error setting password"
      if (!nzchar(input$pw_usr)) {
        twinkle::modal_error("Username not provided", error_title)
      } else if (!nzchar(input$pw_new)) {
        twinkle::modal_error("Password must not be blank", error_title)
      } else if (!identical(input$pw_new, input$pw_chk)) {
        twinkle::modal_error("New passwords do not match", error_title)
      } else if (!isTRUE(auth$is_admin) &&
                  !twinkle::verify_password(input$pw_usr, input$pw_old,
                                            passwordfile)) {
        twinkle::modal_error("Incorrect old password", error_title)
      } else {
        twinkle::update_user_password(username, password, passwordfile)
        shiny::updateTextInput(session, "pw_usr", value = "")
        shiny::updateTextInput(session, "pw_old", value = "")
        shiny::updateTextInput(session, "pw_new", value = "")
        shiny::updateTextInput(session, "pw_chk", value = "")
      }
    })
}


server_main_panel <- function(is_administrator) {
  if (is_administrator) {
    pw_usr <- shiny::selectInput("pw_usr", "Username",
                                 twinkle::read_users(passwordfile))
  } else {
    pw_usr <- shiny::textInput("pw_usr", "Username")
  }

  shiny::tagList(
    pw_usr,
    if (!is_administrator) shiny::passwordInput("pw_old", "Old password"),
    shiny::passwordInput("pw_new", "New password"),
    shiny::passwordInput("pw_chk", "Confirm new password"),
    shiny::actionButton("pw_set", "Set password", class = "btn-success"))
}


shiny::shinyApp(ui = ui, server = server)
