read_app_config <- function(path_config, name) {
  cfg <- read_config(path_config)
  app <- cfg$apps[[name]]
  if (is.null(app)) {
    cli::cli_abort("No such app '{name}'")
  }
  app
}


read_config <- function(path_config) {
  if (!file.exists(path_config)) {
    cli::cli_abort("Configuration file '{path_config}' not found")
  }
  dat <- yaml::read_yaml(path_config)
  extra <- setdiff(names(dat), "apps")
  if (length(extra) > 0) {
    cli::cli_abort("Expected 'site.yml' to only have top-level field 'apps'")
  }
  if (is.null(names(dat$apps))) {
    cli::cli_abort("Expected 'site.yml:apps' to be a named list")
  }
  list(apps = Map(check_app_config, names(dat$apps), dat$apps))
}


check_app_config <- function(name, cfg) {
  required <- c("username", "repo")
  allowed <- c(required, "branch", "subdir", "private")
  msg <- setdiff(required, names(cfg))
  if (length(msg) > 0) {
    cli::cli_abort("Required fields missing in 'site.yml:apps:{name}': {msg}")
  }
  extra <- setdiff(names(cfg), allowed)
  if (length(extra) > 0) {
    cli::cli_abort("Unknown fields present in 'site.yml:apps:{name}':  {extra}")
  }
  if (!("branch" %in% names(cfg))) {
    cfg["branch"] <- list(NULL)
  }
  cfg$private <- isTRUE(cfg$private)
  cfg$name <- name
  cfg
}
