path_repo <- function(root, name) {
  file.path(root, "repos", name)
}


path_app <- function(root, name) {
  file.path(root, "apps", name)
}


path_app_staging <- function(root, name) {
  file.path(root, "apps/staging", name)
}


path_lib <- function(root, name) {
  file.path(root, "libs", name)
}


path_src <- function(root, name, subdir) {
  ret <- path_repo(root, name)
  if (is.null(subdir)) ret else file.path(ret, subdir)
}
