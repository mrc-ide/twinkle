test_that("can construct arguments to sync directory", {
  expect_equal(
    rsync_mirror_directory_args("a", "b", NULL),
    c("-auv", "--delete", "a/", "b/"))
  expect_equal(
    rsync_mirror_directory_args("a/", "b/", c("x", "y")),
    c("-auv", "--exclude", "x", "--exclude", "y", "--delete","a/", "b/"))
})


test_that("can sync an app", {
  root <- withr::local_tempdir()
  name <- "app"
  repo <- path_repo(root, name)
  create_simple_git_repo(repo)
  create_dummy_library(root, name)

  suppressMessages(sync_app(name, NULL, TRUE, root, verbose = FALSE))

  path <- path_app(root, name, TRUE)
  expect_true(file.exists(file.path(path, "app.R")))
  expect_true(file.exists(file.path(path, ".lib/pkg/file")))
  expect_false(file.exists(file.path(path, ".git")))
})


test_that("can sync an app in a subdirectory", {
  root <- withr::local_tempdir()
  name <- "app"
  repo <- path_repo(root, name)
  create_simple_git_repo(repo, subdir = "some/path")
  create_dummy_library(root, name)

  suppressMessages(sync_app(name, "some/path", FALSE, root, verbose = FALSE))

  path <- path_app(root, name, FALSE)
  expect_true(file.exists(file.path(path, "app.R")))
  expect_true(file.exists(file.path(path, ".lib/pkg/file")))
  expect_false(file.exists(file.path(path, ".git")))
})
