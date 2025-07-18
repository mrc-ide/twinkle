test_that("can create a deploy key", {
  root <- withr::local_tempdir()
  cfg <- withr::local_tempfile()
  withr::local_envvar(c(TWINKLE_ROOT = root, TWINKLE_CONFIG = cfg))

  writeLines(
    c("apps:",
      "  myapp:",
      "    username: user",
      "    repo: repo",
      "    branch: main",
      "    private: true"),
    cfg)
  msg <- capture_messages(pub <- twinkle_deploy_key("myapp"))
  expect_length(msg, 2)
  expect_match(msg[[1]], "Add the public key to github at")
  expect_equal(trimws(msg[[2]]), pub)
  expect_true(file.exists(path_deploy_key(root, "myapp")))
})


test_that("can refuse create a deploy key for public app", {
  root <- withr::local_tempdir()
  cfg <- withr::local_tempfile()
  withr::local_envvar(c(TWINKLE_ROOT = root, TWINKLE_CONFIG = cfg))

  writeLines(
    c("apps:",
      "  myapp:",
      "    username: user",
      "    repo: repo",
      "    branch: main"),
    cfg)
  expect_error(twinkle_deploy_key("myapp"),
               "Not adding deploy key, as 'myapp' is not private")
})


test_that("can restart an application", {
  root <- withr::local_tempdir()
  cfg <- withr::local_tempfile()
  withr::local_envvar(c(TWINKLE_ROOT = root, TWINKLE_CONFIG = cfg))
  dir_create(path_app(root, "foo", FALSE))
  expect_error(
    twinkle_restart("foo", FALSE),
    "Not restarting 'foo' (staging) as it is not synced",
    fixed = TRUE)
  expect_message(
    twinkle_restart("foo", TRUE),
    "Requested restart of 'foo' (production)",
    fixed = TRUE)
  expect_true(file.exists(
    file.path(path_app(root, "foo", FALSE), "restart.txt")))
})


test_that("can delete an application", {
  root <- withr::local_tempdir()
  withr::local_envvar(c(TWINKLE_ROOT = root))

  name <- "app"
  paths <- c(path_app(root, name, FALSE),
             path_app(root, name, TRUE),
             path_lib(root, name),
             path_repo(root, name))
  for (p in paths) {
    dir_create(p)
  }

  msg1 <- capture_messages(twinkle_delete_app(name))
  expect_length(msg1, 4)
  expect_match(msg1[[1]], "Deleted production instance for 'app'")
  expect_match(msg1[[4]], "Deleted source for 'app'")
  expect_false(any(file.exists(paths)))

  msg2 <- capture_messages(twinkle_delete_app(name))
  expect_length(msg2, 1)
  expect_match(msg2[[1]], "The source for 'app' was not found")
})


test_that("Can call repo_update with branch", {
  root <- withr::local_tempdir()
  withr::local_envvar(c(TWINKLE_ROOT = root))
  mock_read_app_config <- function(config, name) {
    list(name = "myapp", username = "bob", repo = "repo",
         branch = "mybranch", private = FALSE)
  }

  mockery::stub(twinkle_update_src, "read_app_config", mock_read_app_config)
  mock_repo_update <- mockery::mock()
  mockery::stub(twinkle_update_src, "repo_update", mock_repo_update)

  twinkle_update_src("myapp", "dev-branch")

  args <- mockery::mock_args(mock_repo_update)[[1]]
  expect_equal(args, list("myapp", "bob", "repo", "dev-branch", FALSE, root))
})


test_that("Can call repo_update without branch", {
  root <- withr::local_tempdir()
  withr::local_envvar(c(TWINKLE_ROOT = root))
  mock_read_app_config <- function(config, name) {
    list(name = "myapp", username = "bob", repo = "repo",
         branch = "mybranch", private = TRUE)
  }

  mockery::stub(twinkle_update_src, "read_app_config", mock_read_app_config)
  mock_repo_update <- mockery::mock()
  mockery::stub(twinkle_update_src, "repo_update", mock_repo_update)

  twinkle_update_src("myapp")

  args <- mockery::mock_args(mock_repo_update)[[1]]
  expect_equal(args, list("myapp", "bob", "repo", "mybranch", TRUE, root))
})


test_that("Can call build_library", {
  root <- withr::local_tempdir()
  withr::local_envvar(c(TWINKLE_ROOT = root))
  mock_read_app_config <- function(config, name) {
    list(name = "myapp", subdir = "inner")
  }

  mockery::stub(twinkle_install_packages, "read_app_config", mock_read_app_config)
  mock_build_library <- mockery::mock()
  mockery::stub(twinkle_install_packages, "build_library", mock_build_library)

  twinkle_install_packages("myapp")

  args <- mockery::mock_args(mock_build_library)[[1]]
  expect_equal(args, list("myapp", "inner", root))
})


test_that("Can call sync on staging", {
  root <- withr::local_tempdir()
  withr::local_envvar(c(TWINKLE_ROOT = root))
  mock_read_app_config <- function(config, name) {
    list(name = "myapp", subdir = "inner")
  }

  mockery::stub(twinkle_sync, "read_app_config", mock_read_app_config)
  mock_sync_app <- mockery::mock()
  mockery::stub(twinkle_sync, "sync_app", mock_sync_app)

  twinkle_sync("myapp", TRUE)

  args <- mockery::mock_args(mock_sync_app)[[1]]
  expect_equal(args, list("myapp", "inner", staging = TRUE, root = root))
})


test_that("Can call sync on production", {
  root <- withr::local_tempdir()
  withr::local_envvar(c(TWINKLE_ROOT = root))
  mock_read_app_config <- function(config, name) {
    list(name = "myapp", subdir = "inner")
  }

  mockery::stub(twinkle_sync, "read_app_config", mock_read_app_config)
  mock_sync_app <- mockery::mock()
  mockery::stub(twinkle_sync, "sync_app", mock_sync_app)

  twinkle_sync("myapp", FALSE)

  args <- mockery::mock_args(mock_sync_app)[[1]]
  expect_equal(args, list("myapp", "inner", staging = FALSE, root = root))
})


test_that("Can update in one shot to staging", {
  root <- withr::local_tempdir()

  mock_src <- mockery::mock()
  mock_pkg <- mockery::mock()
  mock_sync <- mockery::mock()

  mockery::stub(twinkle_deploy, "twinkle_update_src", mock_src)
  mockery::stub(twinkle_deploy, "twinkle_install_packages", mock_pkg)
  mockery::stub(twinkle_deploy, "twinkle_sync", mock_sync)

  twinkle_deploy("myapp", FALSE)

  mockery::expect_called(mock_src, 1)
  expect_equal(mockery::mock_args(mock_src)[[1]], list("myapp"))
  mockery::expect_called(mock_pkg, 1)
  expect_equal(mockery::mock_args(mock_pkg)[[1]], list("myapp"))
  mockery::expect_called(mock_sync, 1)
  expect_equal(mockery::mock_args(mock_sync)[[1]],
               list("myapp", staging = TRUE))
})


test_that("Can update in one shot to production", {
  root <- withr::local_tempdir()

  mock_src <- mockery::mock()
  mock_pkg <- mockery::mock()
  mock_sync <- mockery::mock()

  mockery::stub(twinkle_deploy, "twinkle_update_src", mock_src)
  mockery::stub(twinkle_deploy, "twinkle_install_packages", mock_pkg)
  mockery::stub(twinkle_deploy, "twinkle_sync", mock_sync)

  twinkle_deploy("myapp", TRUE)

  mockery::expect_called(mock_src, 1)
  expect_equal(mockery::mock_args(mock_src)[[1]], list("myapp"))
  mockery::expect_called(mock_pkg, 1)
  expect_equal(mockery::mock_args(mock_pkg)[[1]], list("myapp"))
  mockery::expect_called(mock_sync, 2)
  expect_equal(mockery::mock_args(mock_sync)[[1]],
               list("myapp", staging = TRUE))
  expect_equal(mockery::mock_args(mock_sync)[[2]],
               list("myapp", staging = FALSE))
})


test_that("can list apps", {
  cfg <- withr::local_tempfile()
  withr::local_envvar(c(TWINKLE_CONFIG = cfg))

  writeLines(
    c("apps:",
      "  myapp:",
      "    username: user",
      "    repo: repo",
      "    branch: main",
      "  otherapp:",
      "    username: user",
      "    repo: other",
      "    branch: main"),
    cfg)

  expect_equal(twinkle_list(), c("myapp", "otherapp"))
  expect_equal(twinkle_list("app"), c("myapp", "otherapp"))
  expect_equal(twinkle_list("^my"), "myapp")
  expect_equal(twinkle_list("^x"), character())
})
