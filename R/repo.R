repo_update <- function(name, username, repo, branch, private, root,
                        verbose = TRUE) {
  dest <- path_repo(root, name)
  key <- repo_key(root, name, private)
  url <- repo_url(username, repo, private)
  if (!file.exists(dest)) {
    cli::cli_h1("Cloning {name} (from github: {username}/{repo})")
    dir_create(dirname(dest))
    gert::git_clone(url, dest, ssh_key = key, verbose = verbose)
    repo_checkout_branch(name, branch, root)
  } else {
    cli::cli_h1("Updating sources for {name}")
    repo_check_remote(dest, url)
    gert::git_fetch(repo = dest, ssh_key = key, verbose = verbose)
  }
  repo_update_lfs(dest)
  repo_checkout_branch(name, branch, root)
}


repo_url <- function(username, repo, private) {
  if (private) {
    sprintf("git@github.com:%s/%s", username, repo)
  } else {
    sprintf("https://github.com/%s/%s", username, repo)
  }
}


repo_checkout_branch <- function(name, branch, root) {
  repo <- path_repo(root, name)
  branch <- repo_select_branch(branch, repo)
  ref_remote <- sprintf("origin/%s", branch)
  current <- gert::git_branch(repo = repo)
  if (current == branch) {
    gert::git_reset_hard(ref = ref_remote, repo = repo)
  } else {
    gert::git_reset_hard(repo = repo)
    gert::git_branch_create(branch,
                            ref = ref_remote,
                            force = TRUE,
                            repo = repo)
  }
  last_repo_id(root, name)
}


repo_select_branch <- function(branch, repo) {
  if (is.null(branch)) {
    basename(gert::git_remote_info(repo = repo)$head)
  } else {
    branch
  }
}


repo_uses_lfs <- function(path) {
  path_git_attributes <- file.path(path, ".gitattributes")
  if (!file.exists(path_git_attributes)) {
    return(FALSE)
  }
  data <- readLines(path_git_attributes)
  any(grepl("\\bfilter=lfs\\b", data))
}


repo_update_lfs <- function(path) {
  if (repo_uses_lfs(path)) {
    cli::cli_h2("Updating LFS data")
    withr::with_dir(
      path,
      system2_or_throw("git", c("lfs", "pull")))
  }
}


repo_key <- function(root, name, private) {
  if (!private) {
    return(NULL)
  }
  path <- path_deploy_key(root, name)
  if (!file.exists(path)) {
    cli::cli_abort(
      "Deploy key for '{name}' does not exist yet",
      i = "You might run {.code ./twinkle deploy-key {name}}")
  }
  path
}


repo_check_remote <- function(path, url) {
  prev <- gert::git_remote_info("origin", repo = path)$url
  if (!identical(prev, url)) {
    cli::cli_abort(
      c("Remote url has changed, can't update sources",
        i = "Previous: {prev}",
        i = "Current: {url}",
        i = "You should delete the application and try again"))
  }
}


last_repo_id <- function(root, name) {
  repo <- path_repo(root, name)
  gert::git_info(repo = repo)$commit
}
