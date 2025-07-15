repo_update <- function(name, username, repo, branch, root) {
  dest <- path_repo(root, name)
  if (!file.exists(dest)) {
    repo_init(name, username, repo, branch, root)
  } else {
    repo_update_existing(name, branch, root)
  }
}


repo_init <- function(name, username, repo, branch, root) {
  cli::cli_h1("Cloning {name} (from github: {username}/{repo})")
  dest <- path_repo(root, name)
  if (file.exists(dest)) {
    cli::cli_abort("'{name}' already exists at {dest}")
  }
  url <- sprintf("https://github.com/%s/%s", username, repo)
  dir_create(dirname(dest))
  gert::git_clone(url, dest)
  if (!is.null(branch)) {
    repo_checkout_branch(name, branch, root)
  }
}


repo_update_existing <- function(name, branch, root) {
  cli::cli_h1("Updating sources for {name}")
  repo <- path_repo(root, name)
  gert::git_fetch(repo = repo)
  repo_checkout_branch(name, branch, root)
}


repo_checkout_branch <- function(name, branch, root) {
  repo <- path_repo(root, name)
  if (is.null(branch)) {
    branch <- repo_default_branch(repo)
  }
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


repo_default_branch <- function(repo) {
  basename(gert::git_remote_info(repo = repo)$head)
}
