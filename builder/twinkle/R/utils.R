`%||%` <- function(a, b) {
  if (is.null(a)) b else a
}


read_string <- function(filename) {
  readChar(filename, file.size(filename))
}


twinkle_file <- function(path) {
  system.file(path, package = "twinkle", mustWork = TRUE)
}


write_if_changed <- function(str, dest, collapse = FALSE, description = NULL) {
  if (collapse) {
    str <- paste0(str, "\n", collapse = "")
  }
  description <- description %||% sprintf("'%s'", dest)
  write <- !(file.exists(dest) && identical(read_string(dest), str))
  if (write) {
    message(sprintf("Writing: %s", description))
    writeChar(str, dest)
  } else {
    message(sprintf("Skipping: %s", description))
  }
  invisible(write)
}
