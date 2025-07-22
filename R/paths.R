path_repo <- function(root, name) {
  file.path(root, "repos", name)
}


path_app <- function(root, name, production) {
  file.path(root, if (production) "apps" else "apps/staging", name)
}


path_lib <- function(root, name) {
  file.path(root, "libs", name)
}


path_history <- function(root, name) {
  file.path(root, "history", name)
}


path_src <- function(root, name, subdir) {
  ret <- path_repo(root, name)
  if (is.null(subdir)) ret else file.path(ret, subdir)
}


path_deploy_key <- function(root, name) {
  file.path(root, "keys", name)
}


path_logs <- function(root) {
  file.path(root, "logs")
}
