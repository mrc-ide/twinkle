test_that("can clone project", {
  skip("for now")
  path <- withr::local_tempdir()
  repo_update("starmeds", "mrc-ide", "starmeds", NULL, path, verbose = FALSE)
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
  suppressMessages(repo_update(name, user, repo, NULL, root, verbose = FALSE))
  expect_equal(gert::git_info(dest)$commit, sha2)

  ## Amend this commit upstream to create inconsistent history
  gert::git_reset_hard(sha1, repo = upstream)
  writeLines(LETTERS[-1], file.path(upstream, "data"))
  gert::git_add(".", repo = upstream)
  sha3 <- gert::git_commit("third", repo = upstream)

  ## Update our copy to reflect this
  suppressMessages(repo_update(name, user, repo, NULL, root, verbose = FALSE))
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
  suppressMessages(repo_update(name, user, repo, NULL, root, verbose = FALSE))
  expect_equal(gert::git_info(dest)$commit, sha1)

  ## Check out this branch:
  suppressMessages(
    repo_update(name, user, repo, "other", root, verbose = FALSE))
  expect_equal(gert::git_info(dest)$commit, sha2)

  ## Ammend this commit upstream to create inconsistent history
  gert::git_reset_hard(sha1, repo = upstream)
  writeLines(LETTERS[-1], file.path(upstream, "data"))
  gert::git_add(".", repo = upstream)
  sha3 <- gert::git_commit("third", repo = upstream)

  ## Update our copy to reflect this
  suppressMessages(
    repo_update(name, user, repo, "other", root, verbose = FALSE))
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
    repo_update("foo", "user", "repo", NULL, root, verbose = FALSE))
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
  expect_equal(repo_url("user", "repo"), "https://github.com/user/repo")
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
