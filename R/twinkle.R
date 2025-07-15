twinkle_update_app <- function(name,
                               install_packages = TRUE,
                               update_staging = TRUE,
                               update_production = FALSE) {
  root <- find_twinkle_root()
  cfg <- read_config(find_twinkle_config())
  app <- cfg[[name]]
  if (is.null(app)) {
    cli::cli_abort("No such app '{name}'")
  }
  update_app(name, app$username, app$repo, app$branch, root,
             install_packages = install_packages,
             update_staging = update_staging,
             update_production = update_production)
}


read_config <- function(path_config) {
  dat <- yaml::read_yaml(path_config)
  extra <- setdiff(names(dat), "apps")
  if (length(extra)) {
    cli::cli_abort("Expected 'site.yml' to only have top-level field 'apps'")
  }
  if (!is.null(names(dat$apps))) {
    cli::cli_abort("Expected 'site.yml:apps' to be a named list")
  }
  Map(check_app_config, names(dat$apps), dat$apps)
}


check_app_config <- function(name, cfg) {
  ## TODO: add some checks here, all pretty standard stuff.
  cfg$name <- name
  cfg
}


update_app <- function(name, username, repo, branch, root,
                       install_packages = TRUE,
                       update_staging = TRUE,
                       update_production = FALSE) {
  repo_update(name, username, repo, branch, root)
  if (install_packages) {
    build_library(name, root)
  }
  if (update_staging) {
    sync_app(name, staging = TRUE, root = root)
  }
  if (update_production) {
    sync_app(name, staging = FALSE, root = root)
  }
}


find_twinkle_root <- function() {
  root <- Sys.getenv("TWINKLE_ROOT", NA_character_)
  if (is.na(root)) {
    cli::cli_abort("Expected environment variable 'TWINKLE_ROOT' to be set")
  }
  root
}


find_twinkle_config <- function() {
  root <- Sys.getenv("TWINKLE_CONFIG", NA_character_)
  if (is.na(root)) {
    cli::cli_abort("Expected environment variable 'TWINKLE_CONFIG' to be set")
  }
  root
}
