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
##' @return Invisibly, the sha of the HEAD of the repository
##' @export
twinkle_update_src <- function(name, branch = NULL) {
  root <- find_twinkle_root()
  app <- read_app_config(find_twinkle_config(), name)
  branch <- branch %||% app$branch
  sha <- repo_update(app$name, app$username, app$repo, branch, app$private,
                     root)
  history_update(root, name, "update-src", list(sha = sha))
  invisible(sha)
}


##' Install packages for an app
##'
##' @title Install app packages
##'
##' @param name Name of the app
##'
##' @return Invisibly, a list containing the sha that the installation
##'   was based on and the conan installation id from the installation
##'
##' @export
twinkle_install_packages <- function(name) {
  root <- find_twinkle_root()
  app <- read_app_config(find_twinkle_config(), name)
  dat <- build_library(app$name, app$subdir, root)
  history_update(root, name, "install-packages", dat)
  invisible(dat)
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
##' @return A named character vector with the ids of the repo (last
##'   SHA) and the library (conan id)
##'
##' @export
twinkle_sync <- function(name, production) {
  root <- find_twinkle_root()
  app <- read_app_config(find_twinkle_config(), name)
  dat <- sync_app(app$name, app$subdir, production = production, root = root)
  dat$production <- production
  event <- if (production) "sync-production" else "sync-staging"
  history_update(root, name, event, dat)
  invisible(dat)
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
##' @param production Logical, indicating if we should *additionally*
##'   delete on production too. Otherwise production is left alone.
##'   This allows you to totally redeploy an application but leave it
##'   running until you are happy with the version, then sync it into
##'   place.
##'
##' @return Nothing
##' @export
twinkle_delete_app <- function(name, production = FALSE) {
  root <- find_twinkle_root()
  if (production) {
    delete_loudly(path_app(root, name, TRUE), "production instance", name)
  }
  delete_loudly(path_app(root, name, FALSE), "staging instance", name)
  delete_loudly(path_lib(root, name), "library", name)
  delete_loudly(path_deploy_key(root, name), "deploy key", name)
  delete_loudly(path_repo(root, name), "source", name,
                verbose_if_missing = TRUE)
  history_update(root, name, "delete", list(production = production))
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


##' List or view logs from the shiny server.
##'
##' @title List of view logs
##'
##' @param name Name of the application
##'
##' @param list Logical, indicating if we should list filenames of log
##'   files, rather than show the last, or a particular, log file.
##'
##' @param filename Optional filename, to show a particular log.
##'   Otherwise we print the most recent log.
##'
##' @return A character vector
##' @export
twinkle_logs <- function(name, list = FALSE, filename = NULL) {
  if (list && !is.null(filename)) {
    cli::cli_abort("Can't specify both 'list' and 'filename'")
  }
  root <- find_twinkle_root()
  path <- path_logs(root)
  if (!is.null(filename)) {
    path <- file.path(path, filename)
    if (!file.exists(path)) {
      cli::cli_abort("Log file '{filename}' was not found")
    }
    return(readLines(path))
  }
  pattern <- sprintf("^%s-shiny-[0-9]{8}-[0-9]{6}", name)
  files <- sort(dir(path, pattern), decreasing = TRUE)
  if (length(files) == 0) {
    cli::cli_abort("No logs found for '{name}'")
  }
  if (list) {
    return(files)
  }
  readLines(file.path(path, files[[1]]))
}


##' Query history for an application
##'
##' @title Query application history
##'
##' @param name Name of the application
##'
##' @return Nothing
##' @export
twinkle_history <- function(name) {
  root <- find_twinkle_root()

  dat <- history_status(root, name)

  cli::cli_h1("{name}")

  if (is.null(dat[["update-src"]])) {
    cli::cli_alert_danger("Package source never updated")
  } else {
    src <- dat[["update-src"]]
    sha <- substr(src$data$sha, 1, 8)
    cli::cli_alert_success(
      "Package source at '{sha}', updated {src$time}")
  }

  if (is.null(dat[["install-packages"]])) {
    cli::cli_alert_danger("Library never updated")
  } else {
    pkg <- dat[["install-packages"]]
    if (is.null(pkg$warning)) {
      cli::cli_alert_success("Packages installed at {pkg$time}")
    } else {
      cli::cli_alert_warning("Packages installed at {pkg$time} ({pkg$warning})")
    }
  }

  for (i in c("staging", "production")) {
    info <- dat[[paste0("sync-", i)]]
    if (is.null(info)) {
      cli::cli_alert_danger("Never deployed to {i}")
    } else {
      if (is.null(info$warning)) {
        cli::cli_alert_success("Deployed to {i} at {info$time}")
      } else {
        cli::cli_alert_warning("Deployed to {i} {info$time} ({info$warning})")
      }
    }
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
