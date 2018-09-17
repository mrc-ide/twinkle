read_site_yml <- function(path = ".") {
  ## TODO: yaml validation here too
  dat <- yaml::yaml.load_file(file.path(path, "site.yml"))
  for (i in seq_along(dat$apps)) {
    app <- dat$apps[[i]]
    app$path <- names(dat$apps)[[i]]
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


git_run <- function(args, root, check = TRUE, env = NULL) {
  git <- sys_which("git")
  if (!is.null(root)) {
    args <- c("-C", root, args)
  }
  system3(git, args, check = check, env = env)
}


system3 <- function(command, args, check = FALSE, output = FALSE, env = NULL) {
  if (output) {
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


update_app_source <- function(app, dest) {
  switch(app$type,
         local = update_app_source_local(app, dest),
         github = update_app_source_github(app, dest),
         stop("Unimplemented app type?"))
}


update_app_source_local <- function(app, dest, path_local = "local") {
  message(sprintf("Updating source for '%s'", app$path))
  ## This won't play nicely with provisioning scripts probably, unless
  ## they also have protected paths, but then they might not want
  ## syncing too...
  path_app_upstream <- file.path(path_local, paste0(app$spec, "/"))
  path_app_source <- file.path(dest, app$path)
  protect <- sprintf("--exclude='%s'",
                     c(".lib", ".drat", app$protect$paths))
  args <- c("-vaz", "--delete", protect, path_app_upstream, path_app_source)
  system3("rsync", args, check = TRUE, output = TRUE)
  path_app_source
}


update_app_source_github <- function(app, dest) {
  spec <- remotes::parse_github_repo_spec(app$spec)
  path <- file.path(dest, app$path)
  env <- NULL

  if (is.null(app$auth)) {
    git_url <- sprintf("https://github.com/%s/%s",
                       spec$username, spec$repo)
  } else {
    vault <- vault_client()
    if (app$auth$type == "deploy_key") {
      vault_root <- Sys.getenv("VAULT_ROOT")
      user_repo <- sprintf("%s/%s", spec$username, spec$repo)
      vault_path <- sprintf("%s/deploy-keys/%s", vault_root, user_repo)
      ssh_id <- tempfile()
      writeLines(vault$read(vault_path, "key"), ssh_id)
      Sys.chmod(ssh_id, "600")
      on.exit(unlink(ssh_id))
      env <- sprintf('GIT_SSH_COMMAND="ssh -i %s"', ssh_id)
      git_url <- sprintf("git@github.com:%s/%s.git",
                         spec$username, spec$repo)
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


provision_app <- function(app, dest) {
  ## Root of the application source tree
  path_source <- file.path(dest, app$path)
  ## Root of the app itself within that tree
  path_app <- update_app_source(app, dest)

  message(sprintf("Provisioning '%s'", app$path))
  provision_app <- twinkle_file("provision_app")
  system3(provision_app, c(path_source, path_app),
          check = TRUE, output = TRUE)
}


provision_all <- function(root = ".", dest = "/source") {
  dat <- read_site_yml(root)
  for (app in dat$apps) {
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
  spec <- remotes::parse_github_repo_spec(app$spec)
  path <- file.path(dest, app$path)
  if (nzchar(spec$subdir)) {
    file.path(path, spec$subdir)
  } else {
    path
  }
}


sync_server <- function(root = ".", src = "/source", dest = "/applications",
                        logs = "/logs", static = "/static") {
  dat <- read_site_yml(root)

  system3("chown", c("shiny.shiny", c(dest, logs)), check = TRUE)
  chown <- c("--owner", "--group", "--chown=shiny:shiny")
  common <- c("-vaz", "--delete", chown)

  for (app in dat$apps) {
    message(sprintf("Synchonising '%s'", app$path))
    path_app_src <- application_source_path(app, src)
    path_app_dest <- file.path(dest, app$path)
    protect <- sprintf("--exclude='%s'", app$protect$paths)
    args <- c(common, protect, paste0(path_app_src, "/"), path_app_dest)
    system3("rsync", args, check = TRUE, output = TRUE)
    ## TODO: restart app here if needed!
  }

  known <- names(dat$apps)

  if (file.exists(static)) {
    args <- c(static, "-maxdepth", "1", "-mindepth", "1")
    static_files <- system3("find", args, check = TRUE, output = FALSE)$output
    message("Synchonising static files")
    args <- c(common, static_files, paste0(dest, "/"))
    system3("rsync", args, check = TRUE, output = TRUE)
    known <- c(known, sub(paste0(static, "/"), "", static_files))
  }

  found <- dir(dest, all.files = TRUE, no.. = TRUE)
  extra <- setdiff(found, known)

  if (length(extra) > 0L) {
    message("Removing extra files")
    unlink(file.path(dest, extra), recursive = TRUE)
  }
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
