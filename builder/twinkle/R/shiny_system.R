system_ui <- function(id) {
  ns <- shiny::NS(id)
  shiny::uiOutput(ns("shell_stream"))
}


system_server <- function(input, output, session,
                          command, args, interval = 50L) {
  ns <- session$ns

  logfile <- tempfile()
  file.create(logfile)
  pid <- sys::exec_background(command, args, logfile, logfile)
  check_pid <- sys_check_pid(pid)

  check <- function() {
    info <- file.info(logfile)
    return(paste(logfile, info$mtime, info$size, check_pid()))
  }
  read <- function() {
    status <- check_pid()
    list(logs = read_string(logfile),
         status = status,
         finished = !is.na(status),
         kill = kill,
         logfile = logfile,
         pid = pid)
  }
  kill <- function() {
    tools::pskill(pid)
  }

  process <- shiny::reactivePoll(interval, session, check, read)

  shiny::observeEvent(
    input$kill, {
      kill()
    })

  shiny::observe({
    if (is.null(process)) {
      output$shell_stream <- NULL
    } else {
      res <- process()
      output$shell_stream <- shiny::renderUI(
        shiny::tagList(
          system_status(res$status, ns),
          shiny::pre(res$logs)))
    }
  })

  process
}


system_status <- function(status, ns) {
  if (is.na(status)) {
    status_content <- shiny::tagList(
      shiny::actionButton(ns("kill"), "Kill",
                          class = "btn-danger btn-xs"),
      "Running")
    status_class <- "info"
  } else if (status == 0) {
    status_content <- "Completed"
    status_class <- "success"
  } else {
    status_content <- sprintf("Error with code %s", status)
    status_class <- "danger"
  }

  bootstrap_alert(status_content, status_class)
}


sys_check_pid <- function(pid) {
  status <- NULL
  function() {
    if (is.null(status)) {
      value <- sys::exec_status(pid, FALSE)
      if (!is.na(value)) {
        status <<- value
      }
      value
    } else {
      status
    }
  }
}


bootstrap_alert <- function(content, class = "default") {
  shiny::div(
    class = sprintf("alert alert-%s", class),
    content)
}
