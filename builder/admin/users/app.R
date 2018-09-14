## users:
##
## - list users
## - change password
##   - use admin to create new password
## - remove users

ui <- shiny::fluidPage(
  shiny::titlePanel("User management"),

  shiny::tabsetPanel(
    shiny::tabPanel(
      "Users",
      shiny::textInput("pw_usr", "Username"),
      shiny::passwordInput("pw_old", "Old password"),
      shiny::passwordInput("pw_new", "New password"),
      shiny::passwordInput("pw_chk", "Confirm new password"),
      shiny::actionButton("pw_set", "Set password"))))


server <- function(input, output, session) {
  shiny::observeEvent(
    input$pw_set, {
      if (!nzchar(input$pw_usr)) {
        modal_error("Username not provided")
      } else if (input$pw_old != "old") {
        modal_error("Incorrect old password")
      } else if (!nzchar(input$pw_new)) {
        modal_error("Password must not be blank")
      } else if (!identical(input$pw_new, input$pw_chk)) {
        modal_error("New passwords do not match")
      } else {
        message("Would write out the new password here")
        shiny::updateTextInput(session, "pw_usr", value = "")
        shiny::updateTextInput(session, "pw_old", value = "")
        shiny::updateTextInput(session, "pw_new", value = "")
        shiny::updateTextInput(session, "pw_chk", value = "")
      }
    })
}


modal_error <- function(msg) {
  shiny::showModal(shiny::modalDialog(msg),
                   easyClose = TRUE)
}


verify_password <- function(username, password, passwordfile) {
  res <- system3("htpasswd", c("-v", passwordfile, username, password),
                 check = FALSE, output = FALSE)
  res$success
}


read_users <- function(passwordfile) {
  sub(":.*", "", readLines(passwordfile))
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


`%||%` <- function(a, b) {
  if (is.null(a)) b else a
}



shiny::shinyApp(ui = ui, server = server)
