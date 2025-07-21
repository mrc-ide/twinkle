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

  if (!is.null(ret[["install-packages"]])) {
    current <- ret[["install-packages"]]$data$sha ==
      ret[["update-src"]]$data$sha
    if (!current) {
      ret[["install-packages"]]$warning <-
        "Source has changed since last installation"
    }
  }

  for (i in c("sync-staging", "sync-production")) {
    if (!is.null(ret[[i]])) {
      current_sha <- ret[["update-src"]]$data$sha == ret[[i]]$data$sha
      current_lib <- ret[["install-packages"]]$data$lib == ret[[i]]$data$lib
      if (!current_sha && !current_lib) {
        ret[[i]]$warning <- "Source and packages have changed since last sync"
      } else if (!current_sha) {
        ret[[i]]$warning <- "Source has changed since last sync"
      } else if (!current_lib) {
        ret[[i]]$warning <- "Packages have changed since last sync"
      }
    }
  }

  ret
}


history_render <- function(name, dat) {
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
