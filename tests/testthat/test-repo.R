test_that("can clone project", {
  skip("for now")
  path <- withr::local_tempdir()
  repo_update("starmeds", "mrc-ide", "starmeds", NULL, FALSE, path,
              verbose = FALSE)
  repo <- file.path(path, "repos", "starmeds", "app.R")
  expect_true(file.exists(repo))
})


test_that("can update a git mirror to track upstream", {
  upstream <- withr::local_tempdir()
  root <- withr::local_tempdir()
  name <- "foo"
  dest <- path_repo(root, name)
  user <- "user"
  repo <- "repo"

  sha1 <- create_simple_git_repo(upstream)
  gert::git_clone(upstream, dest, verbose = FALSE)

  ## Update upstream by adding a commit
  writeLines(LETTERS, file.path(upstream, "data"))
  gert::git_add(".", repo = upstream)
  sha2 <- gert::git_commit("second", repo = upstream)

  ## Update our copy to reflect this
  suppressMessages(
    repo_update(name, user, repo, NULL, FALSE, root, verbose = FALSE))
  expect_equal(gert::git_info(dest)$commit, sha2)

  ## Amend this commit upstream to create inconsistent history
  gert::git_reset_hard(sha1, repo = upstream)
  writeLines(LETTERS[-1], file.path(upstream, "data"))
  gert::git_add(".", repo = upstream)
  sha3 <- gert::git_commit("third", repo = upstream)

  ## Update our copy to reflect this
  suppressMessages(
    repo_update(name, user, repo, NULL, FALSE, root, verbose = FALSE))
  expect_equal(gert::git_info(dest)$commit, sha3)
})


test_that("can update a git mirror to track upstream", {
  upstream <- withr::local_tempdir()
  root <- withr::local_tempdir()
  name <- "foo"
  dest <- path_repo(root, name)
  user <- "user"
  repo <- "repo"

  sha1 <- create_simple_git_repo(upstream)
  gert::git_clone(upstream, dest, verbose = FALSE)

  ## Update upstream by adding a commit on a branch
  writeLines(LETTERS, file.path(upstream, "data"))
  gert::git_add(".", repo = upstream)
  gert::git_branch_create("other", repo = upstream)
  sha2 <- gert::git_commit("second", repo = upstream)

  ## Update our copy shows no change if we update main
  suppressMessages(
    repo_update(name, user, repo, NULL, FALSE, root, verbose = FALSE))
  expect_equal(gert::git_info(dest)$commit, sha1)

  ## Check out this branch:
  suppressMessages(
    repo_update(name, user, repo, "other", FALSE, root, verbose = FALSE))
  expect_equal(gert::git_info(dest)$commit, sha2)

  ## Ammend this commit upstream to create inconsistent history
  gert::git_reset_hard(sha1, repo = upstream)
  writeLines(LETTERS[-1], file.path(upstream, "data"))
  gert::git_add(".", repo = upstream)
  sha3 <- gert::git_commit("third", repo = upstream)

  ## Update our copy to reflect this
  suppressMessages(
    repo_update(name, user, repo, "other", FALSE, root, verbose = FALSE))
  expect_equal(gert::git_info(dest)$commit, sha3)
})


test_that("can initialise a repo", {
  skip_if_not_installed("mockery")

  upstream <- withr::local_tempdir()
  sha <- create_simple_git_repo(upstream)
  root <- withr::local_tempdir()
  name <- "foo"
  dest <- path_repo(root, name)

  mockery::stub(repo_update, "repo_url", upstream)

  suppressMessages(
    repo_update("foo", "user", "repo", NULL, FALSE, root, verbose = FALSE))
  expect_equal(gert::git_info(dest)$commit, sha)
  expect_equal(gert::git_branch(dest), gert::git_branch(upstream))
})


test_that("can fall back on default branch", {
  upstream <- withr::local_tempdir()
  root <- withr::local_tempdir()
  name <- "foo"
  dest <- path_repo(root, name)

  create_simple_git_repo(upstream)
  gert::git_clone(upstream, dest, verbose = FALSE)

  branch <- gert::git_branch(upstream)
  expect_equal(repo_select_branch(NULL, dest), branch)
  expect_equal(repo_select_branch(branch, dest), branch)
  expect_equal(repo_select_branch("other", dest), "other")
})


test_that("can build github url", {
  expect_equal(repo_url("user", "repo", FALSE), "https://github.com/user/repo")
  expect_equal(repo_url("user", "repo", TRUE), "git@github.com:user/repo")
})


test_that("can detect if a repo uses lfs", {
  path <- withr::local_tempfile()
  create_simple_git_repo(path)
  expect_false(repo_uses_lfs(path))
  writeLines(
    c("*.RData filter=lfs diff=lfs merge=lfs -text",
      "*.rds filter=lfs diff=lfs merge=lfs -text"),
    file.path(path, ".gitattributes"))
  expect_true(repo_uses_lfs(path))
})


test_that("can update lfs if required", {
  skip_if_not_installed("mockery")
  mock_system2 <- mockery::mock(getwd())
  mockery::stub(repo_update_lfs, "system2_or_throw", mock_system2)
  path <- withr::local_tempfile()
  create_simple_git_repo(path)
  writeLines(
    c("*.RData filter=lfs diff=lfs merge=lfs -text",
      "*.rds filter=lfs diff=lfs merge=lfs -text"),
    file.path(path, ".gitattributes"))
  expect_true(repo_uses_lfs(path))
  res <- suppressMessages(repo_update_lfs(path))
  mockery::expect_called(mock_system2, 1)
  expect_equal(
    mockery::mock_args(mock_system2)[[1]],
    list("git", c("lfs", "pull")))
  expect_equal(res, path)
})


test_that("public repos do not have repo keys", {
  path <- withr::local_tempdir()
  expect_null(repo_key(path, "app", FALSE))
  path_key <- path_deploy_key(path, "app")
  dir_create(dirname(path_key))
  file.create(path_key)
  expect_null(repo_key(path, "app", FALSE))
})


test_that("private repos need repo keys", {
  path <- withr::local_tempdir()
  expect_error(
    repo_key(path, "app", TRUE),
    "Deploy key for 'app' does not exist yet")
  path_key <- path_deploy_key(path, "app")
  dir_create(dirname(path_key))
  file.create(path_key)
  expect_equal(repo_key(path, "app", TRUE), path_key)
})


test_that("can error if the repo url changes", {
  path <- withr::local_tempdir()
  sha <- create_simple_git_repo(path)
  url <- "https://example.com/git"
  gert::git_remote_add(url, repo = path)

  expect_no_error(repo_check_remote(path, url))
  expect_error(
    repo_check_remote(path, "git@example.com/git"),
    "Remote url has changed, can't update sources")
  expect_error(
    repo_check_remote(path, "https://github.com/user/repo"),
    "Remote url has changed, can't update sources")
})
