path_repo <- function(root, name) {
  file.path(root, "repos", name)
}


path_app <- function(root, name, staging) {
  file.path(root, if (staging) "apps/staging" else "apps", name)
}


path_lib <- function(root, name) {
  file.path(root, "libs", name)
}


path_src <- function(root, name, subdir) {
  ret <- path_repo(root, name)
  if (is.null(subdir)) ret else file.path(ret, subdir)
}


path_deploy_key <- function(root, name) {
  file.path(root, "keys", name)
}
