repo_init <- function(name, ref, root) {
  dest <- path_repo(root, name)
  if (file.exists(dest)) {
    cli::cli_abort("'{name}' already exists at {dest}")
  }
  dat <- remotes::parse_github_repo_spec(ref)
  url <- sprintf("https://github.com/%s/%s", dat$username, dat$repo)
  gert::git_clone(url, dest)
}


repo_fetch <- function(name, root) {
  repo <- path_repo(root, name)
  gert::git_fetch(repo = repo)
}


repo_checkout_branch <- function(name, branch, root) {
  repo <- path_repo(root, name)
  gert::git_reset_hard(repo = repo)
  gert::git_branch_create(branch,
                          ref = sprintf("origin/%s", branch),
                          force = TRUE,
                          repo = repo)
}


path_repo <- function(root, name) {
  file.path(root, "repos", name)
}


path_app <- function(root, name) {
  file.path(root, "apps", name)
}


path_app_staging <- function(root, name) {
  file.path(root, "apps/staging", name)
}


path_lib <- function(root, name) {
  file.path(root, "libs", name)
}
