##' Update source for a twinkle application.
##'
##' @title Update twinke app source
##'
##' @param name Name of the app
##'
##' @param branch Optionally, the branch to use (e.g., if testing a
##'   branch on staging).  This overrides the configuration within the
##'   application.
##'
##' @return Nothing
##' @export
twinkle_update_src <- function(name, branch = NULL) {
  root <- find_twinkle_root()
  app <- read_app_config(find_twinkle_config(), name)
  branch <- branch %||% app$branch
  repo_update(app$name, app$username, app$repo, branch, app$private, root)
}


##' Install packages for an app
##'
##' @title Install app packages
##'
##' @param name Name of the app
##'
##' @return Nothing
##' @export
twinkle_install_packages <- function(name) {
  root <- find_twinkle_root()
  app <- read_app_config(find_twinkle_config(), name)
  build_library(app$name, app$subdir, root)
}


##' Sync an app and its library to the staging or production shiny
##' server.
##'
##' @title Sync app
##'
##' @param name Name of the app
##'
##' @param production Logical, indicating if we want to update the
##'   production instance.  If `FALSE`, then staging is updated.
##'
##' @return Nothing
##' @export
twinkle_sync <- function(name, production) {
  root <- find_twinkle_root()
  app <- read_app_config(find_twinkle_config(), name)
  sync_app(app$name, app$subdir, production = production, root = root)
}


##' Show (and if needed, create or recreate) a deploy key for an
##' private application.  Instructions will be printed to explain how
##' to add the key to the repository.  You can have multiple deploy
##' keys for a repository.
##'
##' @title Show or create a deploy key
##'
##' @param name Name of the application within the twinkle configuration
##'
##' @param recreate Logical, indicating if we should create the key
##'   again even if it already exists.
##'
##' @return Invisibly, the public key as a string
##' @export
twinkle_deploy_key <- function(name, recreate = FALSE) {
  root <- find_twinkle_root()
  app <- read_app_config(find_twinkle_config(), name)
  if (!app$private) {
    cli::cli_abort("Not adding deploy key, as '{name}' is not private")
  }
  deploy_key_create(name, recreate, root)
  deploy_key_show_instructions(name, app$username, app$repo, root)
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
  delete_loudly(path_app(root, name, TRUE), "production instance", name)
  delete_loudly(path_app(root, name, FALSE), "staging ginstance", name)
  delete_loudly(path_lib(root, name), "library", name)
  delete_loudly(path_deploy_key(root, name), "deploy key", name)
  delete_loudly(path_repo(root, name), "source", name,
                verbose_if_missing = TRUE)
}


##' All-in-one deployment.  Runs through all steps (update source,
##' install packages and sync to staging and possibly to production).
##' This is intended either for the initial setup of an application or
##' a full update.  For more control use the individual functions
##' [twinkle_update_src()], [twinkle_install_packages()] and
##' [twinkle_sync()]
##'
##' @title ALl-in-one deploy
##'
##' @param name Name of the application within the twinkle
##'   configuration. We don't check that the application actually
##'   exists within your configuration (or indeed even read your
##'   configuration at all) because the application for deletion might
##'   have been removed from the configuration already.
##'
##' @param production Deploy to production (**in addition** to staging)
##'
##' @return Nothing
##' @export
twinkle_deploy <- function(name, production = FALSE) {
  twinkle_update_src(name)
  twinkle_install_packages(name)
  twinkle_sync(name, production = FALSE)
  if (production) {
    twinkle_sync(name, production = TRUE)
  }
}


##' Tell shiny to restart an application.  This will trigger for
##' *both* the staging and production versions.  This needs to be done
##' rarely, but would be needed in the case where the library has been
##' updated but the application source has not in order to force shiny
##' to pick up the new packages.
##'
##' This will not work for multiple applications that are present
##' within a directory!  We would need to extend things so that we
##' knew where these different applications were (either in the
##' configuration file, or by applying heuristics through the source
##' tree) and touch a file in every sub application.  This has
##' historically been an issue for the old odin/shiny shortcourse app,
##' but that is now obsolete.  You can always restart the server
##' itself of course.
##'
##' @title Restart an application
##'
##' @param name Name of the application within the twinkle
##'   configuration. We don't check that the application actually
##'   exists within your configuration (or indeed even read your
##'   configuration at all) because the application for deletion might
##'   have been removed from the configuration already.
##'
##' @param production Logical, indicating if we should restart the
##'   production version (rather than the staging version).
##'
##' @return Nothing
##' @export
twinkle_restart <- function(name, production) {
  root <- find_twinkle_root()
  path <- path_app(root, name, production)
  type <- if (production) "production" else "staging"
  if (!file.exists(path)) {
    cli::cli_abort("Not restarting '{name}' ({type}) as it is not synced")
  }
  file.create(file.path(path, "restart.txt"))
  cli::cli_alert_success("Requested restart of '{name}' ({type})")
}


##' List known apps from the config
##'
##' @title List apps
##'
##' @param pattern Optional pattern to search for (a regular expression)
##'
##' @return A character vector
##' @export
twinkle_list <- function(pattern = NULL) {
  cfg <- read_config(find_twinkle_config())
  apps <- names(cfg$apps)
  if (!is.null(pattern)) {
    apps <- grep(pattern, apps, value = TRUE)
  }
  apps
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
