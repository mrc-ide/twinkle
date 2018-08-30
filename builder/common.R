read_site_yml <- function() {
  ## TODO: yaml validation here too
  dat <- yaml::yaml.load_file("site.yml")
  for (i in seq_along(dat$apps)) {
    app <- dat$apps[[i]]
    app$path <- names(dat$apps)[[i]]

    if (app$type == "github") {
      spec <- remotes::parse_github_repo_spec(app$spec)
      path_source <- file.path("sources", app$path)
      if (nzchar(spec$subdir)) {
        path_source <- file.path(path_source, spec$subdir)
      }
    } else if (app$type == "local") {
      path_source <- app$spec
    } else {
      stop(sprintf("Unknown app type '%s'", app$type))
    }
    app$path_source <- path_source
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


git_run <- function(args, root, check = TRUE) {
  git <- sys_which("git")
  if (!is.null(root)) {
    args <- c("-C", root, args)
  }
  system3(git, args, check = check)
}


system3 <- function(command, args, check = FALSE, output = FALSE) {
  if (output) {
    code <- system2(command, args, stdout = "", stderr = "")
    logs <- NULL
  } else {
    logs <- suppressWarnings(
      system2(command, args, stdout = TRUE, stderr = TRUE))
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
  if (file.exists(path)) {
    git_run("fetch", path)
  } else {
    dir.create(dirname(path), FALSE, TRUE)
    git_url <- sprintf("https://github.com/%s/%s",
                       spec$username, spec$repo)
    git_run(c("clone", git_url, path), NULL)
  }

  ## NOTE: PR not allowed
  if (!nzchar(spec$ref)) {
    ## NOTE: this assumes master is default branch which is not going
    ## to always be th case.
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
  provision_app <- sys_which("provision_app")
  system3(provision_app, app$path_source, check = TRUE, output = TRUE)

  ## This should only happen if the provisioning changed I think.
  file.create(file.path(app$path_source, "restart.txt"))

  dest <- file.path("/applications", app$path)
  protect <- sprintf("--exclude='%s'", app$protect)
  paste(c("rsync", "-vaz", "--delete", protect,
          paste0(app$path_source, "/"), dest), collapse = " ")
}


provision_all <- function(dat) {
  sync <- vapply(dat$apps, provision_app, character(1))
  dir.create("sources", FALSE, TRUE)
  writeLines(c("set -e", sync), "sources/sync.sh")
}
