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
    writeLines(str, dest, sep = "")
  } else {
    message(sprintf("Skipping: %s", description))
  }
  invisible(write)
}


vlapply <- function(X, FUN, ...) {
  vapply(X, FUN, logical(1), ...)
}


vcapply <- function(X, FUN, ...) {
  vapply(X, FUN, character(1), ...)
}


squote <- function(x) {
  sprintf("'%s'", x)
}


filter_null <- function(x) {
  x[!vlapply(x, is.null)]
}


docopt_parse <- function(usage, args) {
  dat <- docopt::docopt(usage, args)
  names(dat) <- gsub("-", "_", names(dat), fixed = TRUE)
  dat
}
