passwordfile <- Sys.getenv("APACHE_PASSWORD_FILE", "/apache_auth/users")
groupfile <- Sys.getenv("APACHE_PASSWORD_FILE", "/apache_auth/groups")
vault_env_file <- Sys.getenv("VAULT_ENV_FILE", "/.vault")

ui <- shiny::fluidPage(
  shiny::titlePanel("User management"),
  shiny::sidebarLayout(
    ## This bit might get done more commonly, and so moved into a
    ## module.
    shiny::sidebarPanel(
      shiny::h3("Admin Login"),
      shiny::textInput("username", "Username"),
      shiny::passwordInput("password", "Password"),
      shiny::div(
        class = "panel-group",
        shiny::actionButton("login", "Login", class = "btn-primary"),
        shiny::actionButton("logout", "Logout", class = "btn-danger")),
      shiny::textOutput("login_status")),
    shiny::mainPanel(
      shiny::uiOutput("main"))))


server <- function(input, output, session) {
  set_vault_env(vault_env_file)
  auth <- shiny::reactiveValues(
    username = NULL, groups = NULL, is_admin = FALSE)

  shiny::observe({
    output$main <- shiny::renderUI(server_main_panel(auth$is_admin))
  })

  shiny::observeEvent(
    input$login, {
      username <- input$username
      if (!nzchar(username)) {
        modal_error("Username not provided", "Error logging in")
      } else if (!nzchar(input$password)) {
        modal_error("Password not provided", "Error logging in")
      } else if (!verify_password(username, input$password, passwordfile)) {
        modal_error("Incorrect username/password", "Error logging in")
      } else {
        groups <- user_membership(username, groupfile)
        auth$username <- username
        auth$groups <- groups
        auth$is_admin <- "dide-internal" %in% auth$groups
        output$login_status <- shiny::renderText(
          sprintf("Logged in as '%s', member of %s", username,
                  paste(squote(groups)), collapse = ", "))
        shiny::updateTextInput(session, "username", value = "")
        shiny::updateTextInput(session, "password", value = "")
      }
    })

  shiny::observeEvent(
    input$logout, {
      auth$username <- NULL
      auth$groups <- NULL
      auth$is_admin <- FALSE
      output$login_status <- NULL
    })

  ## To improve here:
  ##
  ## avoid shell
  shiny::observeEvent(
    input$pw_set, {
      if (!nzchar(input$pw_usr)) {
        modal_error("Username not provided", "Error setting password")
      } else if (!nzchar(input$pw_new)) {
        modal_error("Password must not be blank", "Error setting password")
      } else if (!identical(input$pw_new, input$pw_chk)) {
        modal_error("New passwords do not match", "Error setting password")
      } else if (!isTRUE(auth$is_admin) &&
                  !verify_password(input$pw_usr, input$pw_old, passwordfile)) {
        modal_error("Incorrect old password", "Error setting password")
      } else {
        update_user_password(username, password, passwordfile)
        shiny::updateTextInput(session, "pw_usr", value = "")
        shiny::updateTextInput(session, "pw_old", value = "")
        shiny::updateTextInput(session, "pw_new", value = "")
        shiny::updateTextInput(session, "pw_chk", value = "")
      }
    })
}


server_main_panel <- function(is_administrator) {
  if (is_administrator) {
    pw_usr <- shiny::selectInput("pw_usr", "Username", read_users(passwordfile))
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



## Most of the rest of this can/should go into the twinkle package I
## think.
modal_error <- function(msg, title) {
  shiny::showModal(shiny::modalDialog(msg, title = title, easyClose = TRUE))
}


verify_password <- function(username, password, passwordfile) {
  res <- system3("htpasswd", c("-bv", passwordfile, username, password),
                 check = FALSE, output = FALSE)
  res$success
}


read_groups <- function(groupfile) {
  groups <- strsplit(readLines(groupfile), ":\\s+")
  members <- strsplit(vcapply(groups, "[[", 2L), "\\s+")
  names(members) <- vcapply(groups, "[[", 1L)
  members
}


user_membership <- function(username, groupfile) {
  groups <- read_groups(groupfile)
  i <- vapply(groups, function(x) username %in% x, logical(1))
  names(groups)[i]
}


read_users <- function(passwordfile) {
  sub(":.*", "", readLines(passwordfile))
}


update_user_password <- function(username, password, passwordfile) {
  hash <- twinkle::set_password(username, password)
  prev <- readLines(passwordfile)
  new <- sprintf("%s:%s", username, hash)
  writeLines(c(prev[grepl("^username:", prev)], new),
             passwordfile)
}


system3 <- function(command, args, check = FALSE, output = FALSE, env = NULL) {
  if (output) {
    code <- system2(command, args, stdout = "", stderr = "", env = env)
    logs <- NULL
  } else {
    logs <- suppressWarnings(
      system2(command, args, stdout = TRUE, stderr = TRUE, env = env))
    code <- attr(logs, "status") %||% 0
    attr(logs, "status") <- NULL
  }

  success <- code == 0L

  if (check && !success) {
    if (output) {
      msg <- sprintf("Error code %d running command", code)
    } else {
      msg <- sprintf("Error code %d running command:\n%s", code,
                     paste0("  > ", logs, collapse = "\n"))
    }
    stop(msg)
  }

  list(success = code == 0, code = code, output = logs)
}


set_vault_env <- function(vault_env_file) {
  Sys.unsetenv(c("VAULTR_AUTH_METHOD", "VAULTR_CACHE_DIR"))
  readRenviron(vault_env_file)
}


`%||%` <- function(a, b) {
  if (is.null(a)) b else a
}


vcapply <- function(X, FUN, ...) {
  vapply(X, FUN, "", ...)
}


squote <- function(x) {
  sprintf("'%s'", x)
}


shiny::shinyApp(ui = ui, server = server)
