## It will be nice to be able to override branches to test out a dev
## branch on staging.  So branch=whatever which would imply
## update_production = FALSE for sure.
twinkle_update_app <- function(name,
                               install_packages = TRUE,
                               update_staging = TRUE,
                               update_production = FALSE) {
  root <- find_twinkle_root()
  app <- read_app_config(find_twinkle_config(), name)
  update_app(name, app$username, app$repo, app$branch, root,
             install_packages = install_packages,
             update_staging = update_staging,
             update_production = update_production)
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
