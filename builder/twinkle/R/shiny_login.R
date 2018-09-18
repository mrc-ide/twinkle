login_ui <- function(id) {
  ns <- shiny::NS(id)
  shiny::uiOutput(ns("login_ui"))
}


login_server <- function(input, output, session, passwordfile, groupfile) {
  auth <- shiny::reactiveValues(user = NULL, groups = NULL, is_admin = FALSE)
  ns <- session$ns

  output$login_ui <- login_ui_fn(ns, FALSE)

  shiny::observeEvent(
    input$login, {
      username <- input$username
      password <- input$password
      if (!nzchar(username)) {
        modal_error("Username not provided", "Error logging in")
      } else if (!nzchar(password)) {
        modal_error("Password not provided", "Error logging in")
      } else if (!verify_password(username, password, passwordfile)) {
        modal_error("Incorrect username/password", "Error logging in")
      } else {
        groups <- user_membership(username, groupfile)
        auth$username <- username
        auth$groups <- groups
        auth$is_admin <- "dide-internal" %in% auth$groups
        output$login_status <- shiny::renderText(
          sprintf("Logged in as '%s', member of %s", username,
                  paste(squote(groups), collapse = ", ")))
        output$login_ui <- login_ui_fn(ns, TRUE)
      }
    })

  shiny::observeEvent(
    input$logout, {
      auth$username <- NULL
      auth$groups <- NULL
      auth$is_admin <- FALSE
      output$login_status <- NULL
      output$login_ui <- login_ui_fn(ns, FALSE)
    })

  auth
}


login_ui_fn <- function(ns, logged_in) {
  title <- shiny::h3("Admin Login")
  status <- shiny::textOutput(ns("login_status"))
  if (logged_in) {
    tags <- shiny::tagList(
      title,
      shiny::actionButton(ns("logout"), "Logout", class = "btn-danger"),
      status)
  } else {
    tags <- shiny::tagList(
      title,
      shiny::textInput(ns("username"), "Username"),
      shiny::passwordInput(ns("password"), "Password"),
      shiny::actionButton(ns("login"), "Login", class = "btn-primary"),
      status)
  }
  shiny::renderUI(tags)
}


modal_error <- function(msg, title) {
  shiny::showModal(shiny::modalDialog(msg, title = title, easyClose = TRUE))
}
