## It will be nice to be able to override branches to test out a dev
## branch on staging.  So branch=whatever which would imply
## update_production = FALSE for sure.
twinkle_update_app <- function(name,
                               install_packages = TRUE,
                               update_staging = TRUE,
                               update_production = FALSE) {
  root <- find_twinkle_root()
  app <- read_app_config(find_twinkle_config(), name)
  update_app(app, root,
             install_packages = install_packages,
             update_staging = update_staging,
             update_production = update_production)
}


twinkle_deploy_key_create <- function(name, force = FALSE) {
  root <- find_twinkle_root()
  app <- read_app_config(find_twinkle_config(), name)
  if (!app$private) {
    cli::cli_abort("Not adding deploy key, as '{name}' is not private")
  }
  deploy_key_create(app$name, app$username, app$repo, force, root)
}


update_app <- function(app, root,
                       install_packages = TRUE,
                       update_staging = TRUE,
                       update_production = FALSE) {
  repo_update(app$name, app$username, app$repo, app$branch, app$private, root)
  if (install_packages) {
    build_library(app$name, app$subdir, root)
  }
  if (update_staging) {
    sync_app(app$name, app$subdir, staging = TRUE, root = root)
  }
  if (update_production) {
    sync_app(app$name, app$subdir, staging = FALSE, root = root)
  }
}


find_twinkle_root <- function() {
  sys_getenv("TWINKLE_ROOT")
}


find_twinkle_config <- function() {
  sys_getenv("TWINKLE_CONFIG")
}
