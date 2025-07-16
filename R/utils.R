dir_create <- function(path) {
  dir.create(path, showWarnings = FALSE, recursive = TRUE)
}


sys_which <- function(name) {
  path <- unname(Sys.which(name))
  if (!nzchar(path)) {
    cli::cli_abort("Executable '{name}' was not found on $PATH")
  }
  path
}


add_trailing_slash <- function(path) {
  if (!grepl("/$", path)) paste0(path, "/") else path
}


system2_or_throw <- function(name, args, ..., verbose = TRUE) {
  if (verbose) {
    stdout <- stderr <- ""
  } else {
    stdout <- stderr <- FALSE
  }
  code <- system2(sys_which(name), args, ..., stdout = stdout, stderr = stderr)
  if (code != 0) {
    cli::cli_abort("Command failed with exit code {code}")
  }
}


sys_getenv <- function(name) {
  value <- Sys.getenv(name, NA_character_)
  if (is.na(value)) {
    cli::cli_abort("Expected environment variable '{name}' to be set")
  }
  value
}
