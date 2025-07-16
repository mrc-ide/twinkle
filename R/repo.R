repo_update <- function(name, username, repo, branch, root, verbose = FALSE) {
  dest <- path_repo(root, name)
  if (!file.exists(dest)) {
    cli::cli_h1("Cloning {name} (from github: {username}/{repo})")
    dir_create(dirname(dest))
    gert::git_clone(repo_url(username, repo), dest, verbose = verbose)
    repo_checkout_branch(name, branch, root)
  } else {
    cli::cli_h1("Updating sources for {name}")
    gert::git_fetch(repo = dest, verbose = verbose)
  }
  repo_update_lfs(dest)
  repo_checkout_branch(name, branch, root)
}


repo_url <- function(username, repo) {
  sprintf("https://github.com/%s/%s", username, repo)
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
