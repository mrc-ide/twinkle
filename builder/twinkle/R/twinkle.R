read_site_yml <- function(path = ".") {
  ## TODO: yaml validation here too
  dat <- yaml::yaml.load_file(file.path(path, "site.yml"))
  for (i in seq_along(dat$apps)) {
    app <- dat$apps[[i]]
    app$path <- names(dat$apps)[[i]]

    if (!is.null(app$secret)) {
      for (j in seq_along(app$secret)) {
        app$secret[[j]]$dest <- names(app$secret)[[j]]
        app$secret[[j]]$binary <- isTRUE(app$secret[[j]]$binary)
      }
    }

    if (!is.null(app$schedule)) {
      for (j in seq_along(app$schedule)) {
        app$schedule[[j]]$name <- names(app$schedule)[[j]]
      }
    }

    dat$apps[[i]] <- app
  }
  dat
}


sys_which <- function(name) {
  path <- Sys.which(name)
  if (!nzchar(path)) {
    stop(sprintf("Did not find '%s'", name))
  }
  unname(path)
}


git_run <- function(args, root, check = TRUE, output = FALSE, env = NULL) {
  git <- sys_which("git")
  if (!is.null(root)) {
    args <- c("-C", root, args)
  }
  system3(git, args, check = check, output = output, env = env)
}


system3 <- function(command, args, check = FALSE, output = FALSE, env = NULL) {
  if (is.character(output)) {
    code <- system2(command, args, stdout = output, stderr = output, env = env)
    logs <- readLines(output)
  } else if (output) {
    code <- system2(command, args, stdout = "", stderr = "", env = env)
    logs <- NULL
  } else {
    logs <- suppressWarnings(
      system2(command, args, stdout = TRUE, stderr = TRUE, env = env))
    code <- attr(logs, "status") %||% 0
    attr(logs, "status") <- NULL
  }

  success <- code == 0L

  if (check && !success) {
    if (output) {
      msg <- sprintf("Error code %d running command", code)
    } else {
      msg <- sprintf("Error code %d running command:\n%s", code,
                     paste0("  > ", logs, collapse = "\n"))
    }
    stop(msg)
  }

  list(success = code == 0, code = code, output = logs)
}


`%||%` <- function(a, b) {
  if (is.null(a)) b else a
}


update_app_source <- function(app, dest, output, check) {
  switch(app$type,
         local = update_app_source_local(app, dest, output, check),
         github = update_app_source_github(app, dest, output, check),
         stop("Unimplemented app type?"))
}


update_app_source_local <- function(app, dest, output, check,
                                    path_local = "local") {
  message(sprintf("Updating source for '%s'", app$path))
  ## This won't play nicely with provisioning scripts probably, unless
  ## they also have protected paths, but then they might not want
  ## syncing too...
  path_app_upstream <- file.path(path_local, paste0(app$spec, "/"))
  path_app_source <- file.path(dest, app$path)
  protect <- sprintf("--exclude='%s'",
                     c(".lib", ".drat", app$protect$paths))
  args <- c("-vaz", "--delete", protect, path_app_upstream, path_app_source)
  system3("rsync", args, check = check, output = output)
  path_app_source
}


update_app_source_github <- function(app, dest, output, check) {
  spec <- remotes::parse_github_repo_spec(app$spec)
  path <- file.path(dest, app$path)
  env <- NULL

  if (is.null(app$auth)) {
    git_url <- sprintf("https://github.com/%s/%s",
                       spec$username, spec$repo)
  } else {
    vault <- vault_client()
    vault_root <- Sys.getenv("VAULT_ROOT")
    if (app$auth$type == "deploy_key") {
      user_repo <- sprintf("%s/%s", spec$username, spec$repo)
      vault_path <- sprintf("%s/deploy-keys/%s", vault_root, user_repo)
      ssh_id <- tempfile()
      writeLines(vault$read(vault_path, "key"), ssh_id)
      Sys.chmod(ssh_id, "600")
      on.exit(unlink(ssh_id))
      env <- sprintf('GIT_SSH_COMMAND="ssh -i %s"', ssh_id)
      git_url <- sprintf("git@github.com:%s/%s.git",
                         spec$username, spec$repo)
    } else if (app$auth$type == "github_pat") {
      vault_path <- sprintf("%s/github-pat/%s", app$path)
      pat <- vault$read(vault_path, "value")
      if (is.null(pat)) {
        stop(sprintf("PAT not found for '%s'", app$path))
      }
      git_url <- sprintf("https://%s@github.com/%s/%s",
                         pat, spec$username, spec$repo)
    } else {
      stop("auth mode unsupported")
    }
  }

  update <- file.exists(path)
  message(sprintf("%s source for '%s'",
          if (update) "Updating" else "Cloning", app$path))

  if (update) {
    git_run("fetch", path, env = env)
  } else {
    dir.create(dirname(path), FALSE, TRUE)
    git_run(c("clone", git_url, path), NULL, env = env)
  }

  ## NOTE: PR not allowed, master assumed default branch
  if (!nzchar(spec$ref)) {
    ref <- "origin/master"
  } else {
    ref <- paste0("origin/", spec$ref)
  }
  git_run(c("reset", "--hard", ref), path)

  application_source_path(app, dest)
}


provision_app <- function(app, dest, output = TRUE, check = TRUE) {
  ## Root of the application source tree
  path_source <- file.path(dest, app$path)
  ## Root of the app itself within that tree
  path_app <- update_app_source(app, dest, check, output)

  message(sprintf("Provisioning '%s'", app$path))
  provision_app <- twinkle_file("provision_app")
  system3(provision_app, c(path_source, path_app),
          check = TRUE, output = TRUE)

  provision_app_secrets(app, dest)
}


provision_app_secrets <- function(app, dest) {
  if (is.null(app$secret)) {
    return()
  }

  vault_root <- Sys.getenv("VAULT_ROOT")
  vault <- vaultr::vault_client(quiet = TRUE)

  for (s in app$secret) {
    src <- s$path
    if (!grepl("^/", s$path)) {
      src <- file.path(vault_root, s$path)
    }
    dest_path <- file.path(dest, app$path, s$dest)
    message(sprintf("Writing secret '%s' from '%s'", s$dest, src))
    value <- vault$read(src, s$field)
    if (s$binary) {
      writeBin(openssl::base64_decode(value), dest_path)
    } else {
      writeLines(value, dest_path)
    }
  }
}


provision_all <- function(root = ".", dest = "/staging") {
  dat <- read_site_yml(root)
  for (app in dat$apps) {
    provision_app(app, dest)
  }
}


provision_apps <- function(names, root = ".", dest = "/staging",
                           preclean = FALSE) {
  dat <- read_site_yml(root)
  msg <- setdiff(names, names(dat$apps))
  if (length(msg) > 0L) {
    stop("Unknown application: ", paste(squote(msg), collapse = ", "))
  }
  for (app in dat$apps[names]) {
    path_app <- file.path(dest, app$path)
    if (preclean && file.exists(path_app)) {
      message("Removing previous copy of ", squote(app$path))
      unlink(path_app, recursive = TRUE)
    }
    provision_app(app, dest)
  }
}


vault_client <- function() {
  vaultr::vault_client(quiet = TRUE)
}


hello <- function(...) {
  message("hello!")
  args <- vapply(list(...), identity, character(1))
  n <- length(args)
  if (n == 0L) {
    message(" - no args")
  } else {
    message(sprintf(
      " - %d %s: %s",
      n, ngettext(n, "arg", "args"),
      paste(args, collapse = ", ")))
  }
}


application_source_path <- function(app, dest) {
  if (app$type == "local") {
    file.path(dest, app$spec)
  } else {
    spec <- remotes::parse_github_repo_spec(app$spec)
    path <- file.path(dest, app$path)
    if (nzchar(spec$subdir)) {
      file.path(path, spec$subdir)
    } else {
      path
    }
  }
}


sync_server <- function(root = ".", staging = "/staging",
                        dest = "/applications", logs = "/logs",
                        static = "/static") {
  dat <- read_site_yml(root)

  system3("chown", c("shiny.shiny", c(dest, logs)), check = TRUE)

  for (app in dat$apps) {
    sync_app(app, staging, dest)
  }

  known <- names(dat$apps)

  if (file.exists(static)) {
    args <- c(static, "-maxdepth", "1", "-mindepth", "1")
    static_files <- system3("find", args, check = TRUE, output = FALSE)$output
    message("Synchonising static files")
    chown <- c("--owner", "--group", "--chown=shiny:shiny")
    common <- c("-vaz", chown)
    args <- c(common, static_files, paste0(dest, "/"))
    system3("rsync", args, check = TRUE, output = TRUE)
    known <- c(known, sub(paste0(static, "/"), "", static_files))
  }

  found <- dir(dest, all.files = TRUE, no.. = TRUE)

  i <- grepl("/.+", known)
  known[i] <- dirname(known[i])
  extra <- setdiff(found, known)

  if (length(extra) > 0L) {
    message("Removing extra files: ", paste(squote(extra), collapse = ", "))
    unlink(file.path(dest, extra), recursive = TRUE)
  }
}


sync_app <- function(app, staging, dest, output = TRUE, check = TRUE) {
  message(sprintf("Synchonising '%s'", app$path))
  path_app_src <- application_source_path(app, staging)
  path_app_dest <- file.path(dest, app$path)
  protect <- sprintf("--exclude='%s'", app$protect$paths)
  chown <- c("--owner", "--group", "--chown=shiny:shiny")
  common <- c("-vaz", "--delete", chown)
  args <- c(common, protect, paste0(path_app_src, "/"), path_app_dest)
  dir.create(path_app_dest, FALSE, TRUE)
  system3("rsync", args, check = check, output = output)
}


add_deploy_key <- function(user_repo, overwrite = FALSE) {
  re <- "^([^/]+)/([^/]+)$"
  if (!grepl(re, user_repo)) {
    stop("Expected 'repo' in the format username/repo")
  }
  user <- sub(re, "\\1", user_repo)
  repo <- sub(re, "\\2", user_repo)

  vault_root <- Sys.getenv("VAULT_ROOT")

  url_key <- sprintf("https://github.com/%s/settings/keys/new", user_repo)
  vault_path <- sprintf("%s/deploy-keys/%s", vault_root, user_repo)

  vault <- vaultr::vault_client(quiet = TRUE)

  if (!is.null(vault$read(vault_path)) && !overwrite) {
    message(sprintf("Deploy key already exists for '%s'", user_repo))
    message(sprintf("Public key is:\n\n%s", vault$read(vault_path, "pub")))
    return()
  }

  key <- openssl::rsa_keygen()
  str_key <- openssl::write_pem(key, NULL)
  str_pub <- openssl::write_ssh(key, NULL)
  data <- list(key = str_key, pub = str_pub)

  message(sprintf("Writing keys to vault at '%s'", vault_path))
  vault$write(vault_path, data)
  message(sprintf("Add the public key to github at\n  %s\n", url_key))
  message(sprintf("with content:\n\n%s\n", data$pub))
}


add_github_pat <- function(appname, pat, overwrite = FALSE) {
  vault_root <- Sys.getenv("VAULT_ROOT")

  vault_path <- sprintf("%s/github-pat/%s", vault_root, appname)

  vault <- vaultr::vault_client(quiet = TRUE)

  if (!is.null(vault$read(vault_path)) && !overwrite) {
    message(sprintf("GitHub PAT already exists for '%s'", appname))
    return()
  }

  data <- list(value = pat)

  message(sprintf("Writing keys to vault at '%s'", vault_path))
  vault$write(vault_path, data)
}


## Ingredients here:
write_schedule <- function(dest, root = ".", shiny_apps_path = "/shiny/apps") {
  dat <- read_site_yml(root)
  make_job <- function(s, app) {
    if (is.null(s$enabled) || isTRUE(s$enabled)) {
      command <- sprintf("twinkle-task-run %s/%s %s",
                         shiny_apps_path, app$path, s$command)
      list(name = s$name,
           command = command,
           schedule = s$frequency)
    }
  }
  defaults <- list(
    shell = "/bin/bash",
    failsWhen = list(
      nonzeroReturn = TRUE,
      producesStdout = FALSE,
      producesStderr = FALSE))

  jobs <- lapply(dat$apps, function(app)
    filter_null(lapply(app$schedule, make_job, app)))
  jobs <- unlist(jobs, FALSE, FALSE)
  cfg <- list(defaults = defaults)
  if (length(jobs) > 0L) {
    cfg$jobs <- jobs
  }
  write_if_changed(yaml::as.yaml(cfg), dest)
}
