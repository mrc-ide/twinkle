## It will be nice to be able to override branches to test out a dev
## branch on staging.  So branch=whatever which would imply
## update_production = FALSE for sure.
twinkle_update_app <- function(name,
                               clone_repo = TRUE,
                               install_packages = TRUE,
                               update_staging = TRUE,
                               update_production = FALSE,
                               branch = NULL) {
  root <- find_twinkle_root()
  app <- read_app_config(find_twinkle_config(), name)
  update_app(app, root,
             clone_repo = clone_repo,
             install_packages = install_packages,
             update_staging = update_staging,
             update_production = update_production,
             branch = branch)
}


##' Create a deploy key for an private application.  Instructions will
##' be printed to explain how to add the key to the repository.  You
##' can have multiple deploy keys for a repository.
##'
##' @title Create a deploy key
##'
##' @param name Name of the application within the twinkle configuration
##'
##' @param force Logical, indicating if we should create the key again
##'   even if it already exists.
##'
##' @return Nothing
##' @export
twinkle_deploy_key_create <- function(name, force = FALSE) {
  root <- find_twinkle_root()
  app <- read_app_config(find_twinkle_config(), name)
  if (!app$private) {
    cli::cli_abort("Not adding deploy key, as '{name}' is not private")
  }
  deploy_key_create(app$name, app$username, app$repo, force, root)
}


##' Delete an application.  This removes everything associated with
##' the application (depending on how far through deployment you might
##' have been); the real and staging instances, the library, the
##' deploy key (if private) and the source code.  You might want to
##' use this when deleting an application that is no longer needed, or
##' if something untoward has happened and it would be convenient to
##' start from a clean state.
##'
##' @title Delete an application
##'
##' @param name Name of the application within the twinkle
##'   configuration. We don't check that the application actually
##'   exists within your configuration (or indeed even read your
##'   configuration at all) because the application for deletion might
##'   have been removed from the configuration already.
##'
##' @return Nothing
##' @export
twinkle_delete_app <- function(name) {
  root <- find_twinkle_root()
  delete_loudly(path_app(root, name, FALSE), "production instance", name)
  delete_loudly(path_app(root, name, TRUE), "staging instance", name)
  delete_loudly(path_lib(root, name), "library", name)
  delete_loudly(path_deploy_key(root, name), "deploy key", name)
  delete_loudly(path_repo(root, name), "source", name,
                verbose_if_missing = TRUE)
}


update_app <- function(app, root,
                       clone_repo = TRUE,
                       install_packages = TRUE,
                       update_staging = TRUE,
                       update_production = FALSE,
                       branch = NULL) {
  if (is.null(branch)) {
    branch <- app$branch
  }
  if (clone_repo) {
    repo_update(app$name, app$username, app$repo, branch, app$private, root)
  }
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


delete_loudly <- function(path, what, name, verbose_if_missing = FALSE) {
  if (file.exists(path)) {
    unlink(path, recursive = TRUE)
    cli::cli_alert_success("Deleted {what} for '{name}' ({path})")
  } else if (verbose_if_missing) {
    cli::cli_alert_warning("The {what} for '{name}' was not found")
  }
}
