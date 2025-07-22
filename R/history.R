history_update <- function(root, name, action, data) {
  file <- path_history(root, name)
  if (file.exists(file)) {
    prev <- readRDS(file)
  } else {
    prev <- NULL
  }
  new <- data.frame(name = name,
                    time = Sys.time(),
                    action = action,
                    data = I(list(data)))
  dir_create(dirname(file))
  saveRDS(rbind(prev, new), file)
}


history_read <- function(root, name) {
  file <- path_history(root, name)
  if (!file.exists(file)) {
    cli::cli_abort("No history for '{name}'")
  }
  readRDS(file)
}


history_render <- function(name, dat) {
  time <- dat$time
  action <- dat$action
  data <- dat$data
  cli::cli_h1("{name}")
  for (i in seq_len(nrow(dat))) {
    d <- data[[i]]
    if ("sha" %in% names(d)) {
      d$sha <- substr(d$sha, 1, 8)
    }
    d <- sprintf("%s=%s", names(d), unlist(d))
    cli::cli_text("{time[[i]]} {action[[i]]} {d}")
  }
}


history_status <- function(root, name) {
  dat <- history_read(root, name)

  last_occurence <- function(action) {
    i <- dat$action == action
    if (any(i)) {
      ret <- as.list(dat[last(which(i)), ])
      ret$data <- ret$data[[1]]
      ret
    } else {
      NULL
    }
  }

  events <- c(
    "update-src", "install-packages", "sync-staging", "sync-production")
  ret <- lapply(events, last_occurence)
  names(ret) <- events

  sha_src <- ret[["update-src"]]$data$sha
  sha_pkg <- ret[["install-packages"]]$data$sha
  lib_pkg <- ret[["install-packages"]]$data$lib

  if (!is.null(ret[["install-packages"]])) {
    if (!identical(ret[["install-packages"]]$data$sha, sha_src)) {
      ret[["install-packages"]]$warning <-
        "Source has changed since last installation"
    }
  }

  for (i in c("sync-staging", "sync-production")) {
    if (!is.null(ret[[i]])) {
      is_old_sha <- !identical(ret[[i]]$data$sha, sha_src)
      is_old_lib <- !identical(ret[[i]]$data$lib, lib_pkg)
      if (is_old_sha && is_old_lib) {
        ret[[i]]$warning <- "Source and packages have changed since last sync"
      } else if (is_old_sha) {
        ret[[i]]$warning <- "Source has changed since last sync"
      } else if (is_old_lib) {
        ret[[i]]$warning <- "Packages have changed since last sync"
      }
    }
  }

  ret
}


history_status_render <- function(name, dat) {
  cli::cli_h1("{name}")
  history_status_render_update_src(dat[["update-src"]])
  history_status_render_install_packages(dat[["install-packages"]])
  history_status_render_sync(dat[["sync-staging"]], "staging")
  history_status_render_sync(dat[["sync-production"]], "production")
}


history_status_render_update_src <- function(info) {
  if (is.null(info)) {
    cli::cli_alert_danger("Package source never updated")
  } else {
    sha <- substr(info$data$sha, 1, 8)
    cli::cli_alert_success(
      "Package source at '{sha}', updated {info$time}")
  }
}


history_status_render_install_packages <- function(info) {
  if (is.null(info)) {
    cli::cli_alert_danger("Library never updated")
  } else {
    if (is.null(info$warning)) {
      cli::cli_alert_success("Packages installed at {info$time}")
    } else {
      cli::cli_alert_warning(
        "Packages installed at {info$time} ({info$warning})")
    }
  }
}


history_status_render_sync <- function(info, where) {
  if (is.null(info)) {
    cli::cli_alert_danger("Never deployed to {where}")
  } else {
    if (is.null(info$warning)) {
      cli::cli_alert_success("Deployed to {where} at {info$time}")
    } else {
      cli::cli_alert_warning(
        "Deployed to {where} at {info$time} ({info$warning})")
    }
  }
}
