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


system2_or_throw <- function(name, args, ...) {
  code <- system2(sys_which(name), args, ...)
  if (code != 0) {
    cli::cli_abort("Command failed with exit code {code}")
  }
}
