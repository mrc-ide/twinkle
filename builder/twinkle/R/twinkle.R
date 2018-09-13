read_site_yml <- function(path = ".") {
  ## TODO: yaml validation here too
  dat <- yaml::yaml.load_file(file.path(path, "site.yml"))
  for (i in seq_along(dat$apps)) {
    app <- dat$apps[[i]]
    app$path <- names(dat$apps)[[i]]

    if (app$type == "github") {
      spec <- remotes::parse_github_repo_spec(app$spec)
      path_source <- file.path("sources", app$path)
      if (nzchar(spec$subdir)) {
        path_app <- file.path(path_source, spec$subdir)
      } else {
        path_app <- path_source
      }
    } else if (app$type == "local") {
      path_source <- path_app <- app$spec
    } else {
      stop(sprintf("Unknown app type '%s'", app$type))
    }
    app$path_source <- path_source
    app$path_app <- path_app
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


update_app_github_source <- function(app) {
  spec <- remotes::parse_github_repo_spec(app$spec)
  path <- file.path("sources", app$path)
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

  ## NOTE: PR not allowed
  if (!nzchar(spec$ref)) {
    ## NOTE: this assumes master is default branch which is not going
    ## to always be the case.
    ref <- "origin/master"
  } else {
    ref <- paste0("origin/", spec$ref)
  }
  git_run(c("reset", "--hard", ref), path)
}


provision_app <- function(app) {
  if (app$type == "github") {
    update_app_github_source(app)
  }

  message(sprintf("Provisioning '%s'", app$path))
  provision_app <- twinkle_file("provision_app")
  system3(provision_app, c(app$path_source, app$path_app),
          check = TRUE, output = TRUE)

  dest <- file.path("/applications", app$path)

  if (file.exists(dest)) {
    ## This should only happen if the provisioning changed, but that's
    ## hard to detect!
    file.create(file.path(app$path_app, "restart.txt"))
  }

  protect <- sprintf("--exclude='%s'", app$protect)
  paste(c("rsync", "-vaz", "--delete", protect,
          paste0(app$path_app, "/"), dest), collapse = " ")
}


provision_all <- function(path = ".") {
  dat <- read_site_yml(path)
  sync <- vapply(dat$apps, provision_app, character(1))
  if (file.exists("static")) {
    ## TODO:  This can't  handle file  deletions, only deletions from
    ## within directories that are not themselves deleted.
    sync_static <- paste(
      c("rsync", "-vaz", "--delete", "$(find static -maxdepth 1 -mindepth 1)",
        "/applications/"),
      collapse = " ")
    sync <- c(sync, sync_static)
  }

  dir.create("sources", FALSE, TRUE)
  writeLines(c("set -e", sync), "sources/sync.sh")
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


sync_server <- function() {
  system3(twinkle_file("sync_server"), NULL, check = TRUE, output = TRUE)
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
