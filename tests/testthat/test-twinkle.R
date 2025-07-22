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
  dir_create(path_app(root, "foo", TRUE))
  expect_error(
    twinkle_restart("foo", FALSE),
    "Not restarting 'foo' (staging) as it is not synced",
    fixed = TRUE)
  expect_message(
    twinkle_restart("foo", TRUE),
    "Requested restart of 'foo' (production)",
    fixed = TRUE)
  expect_true(file.exists(
    file.path(path_app(root, "foo", TRUE), "restart.txt")))
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

  msg1 <- capture_messages(twinkle_delete_app(name, TRUE))
  expect_length(msg1, 4)
  expect_match(msg1[[1]], "Deleted production instance for 'app'")
  expect_match(msg1[[4]], "Deleted source for 'app'")
  expect_false(any(file.exists(paths)))

  msg2 <- capture_messages(twinkle_delete_app(name))
  expect_length(msg2, 1)
  expect_match(msg2[[1]], "The source for 'app' was not found")
})


test_that("can delete an application but leave production alone", {
  root <- withr::local_tempdir()
  withr::local_envvar(c(TWINKLE_ROOT = root))

  name <- "app"
  paths <- c(path_app(root, name, TRUE),
             path_app(root, name, FALSE),
             path_lib(root, name),
             path_repo(root, name))
  for (p in paths) {
    dir_create(p)
  }

  msg1 <- capture_messages(twinkle_delete_app(name))
  expect_length(msg1, 3)
  expect_match(msg1[[1]], "Deleted staging instance for 'app'")
  expect_match(msg1[[3]], "Deleted source for 'app'")
  expect_false(any(file.exists(paths[-1])))
  expect_true(file.exists(paths[[1]]))
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

  twinkle_sync("myapp", FALSE)

  args <- mockery::mock_args(mock_sync_app)[[1]]
  expect_equal(args, list("myapp", "inner", production = FALSE, root = root))
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

  twinkle_sync("myapp", TRUE)

  args <- mockery::mock_args(mock_sync_app)[[1]]
  expect_equal(args, list("myapp", "inner", production = TRUE, root = root))
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
               list("myapp", production = FALSE))
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
               list("myapp", production = FALSE))
  expect_equal(mockery::mock_args(mock_sync)[[2]],
               list("myapp", production = TRUE))
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


test_that("Can show logs", {
  logs <- withr::local_tempdir()
  cfg <- withr::local_tempfile()
  withr::local_envvar(c(TWINKLE_LOGS = logs, TWINKLE_CONFIG = cfg))

  files <- c(
    "epiestim-shiny-20250721-133754-35995.log",
    "starmeds-budget-tool-shiny-20250717-142545-35579.log",
    "starmeds-budget-tool-shiny-20250717-142722-38769.log",
    "starmeds-budget-tool-shiny-20250717-142857-35669.log",
    "starmeds-budget-tool-shiny-20250718-153936-36235.log")
  for (i in seq_along(files)) {
    writeLines(rep(letters[i], 5), file.path(logs, files[[i]]))
  }

  expect_equal(twinkle_logs("starmeds-budget-tool"), rep("e", 5))
  expect_equal(
    twinkle_logs(
      "starmeds-budget-tool",
      filename = "starmeds-budget-tool-shiny-20250717-142857-35669.log"),
    rep("d", 5))
  expect_equal(
    twinkle_logs("starmeds-budget-tool", list = TRUE),
    rev(files[-1]))
  expect_equal(twinkle_logs("epiestim"), rep("a", 5))
  expect_error(twinkle_logs("other"),
               "No logs found for 'other'")
  expect_error(
    twinkle_logs(
      "starmeds-budget-tool",
      filename = "20250717-142857-35669.log"),
    "Log file '20250717-142857-35669.log' was not found")
  expect_error(
    twinkle_logs("starmeds-budget-tool", list = TRUE, filename = "yeah"),
    "Can't specify both 'list' and 'filename'")
})


test_that("can get status", {
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

  dat <- new.env()
  mock_status <- mockery::mock(dat)
  mock_render <- mockery::mock()

  mockery::stub(twinkle_status, "history_status", mock_status)
  mockery::stub(twinkle_status, "history_status_render", mock_render)

  twinkle_status("myapp")

  mockery::expect_called(mock_status, 1)
  expect_equal(mockery::mock_args(mock_status)[[1]], list(root, "myapp"))

  mockery::expect_called(mock_render, 1)
  expect_equal(mockery::mock_args(mock_render)[[1]], list("myapp", dat))
})


test_that("can print status for app", {
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

  expect_error(twinkle_status("myapp"), "No history for 'myapp'")
  expect_error(twinkle_status("other"), "No such app 'other'")

  sha <- random_sha()
  history_update(root, "myapp", "update-src", list(sha = sha))
  msg <- capture_messages(twinkle_status("myapp"))
  expect_match(msg, "Package source at '.+', updated", all = FALSE)
  expect_match(msg, "Library never updated", all = FALSE)
})


test_that("can show history for app", {
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

  sha <- random_sha()
  history_update(root, "myapp", "update-src", list(sha = sha))
  msg <- capture_messages(twinkle_history("myapp"))

  expect_match(msg, "update-src sha=", all = FALSE)
})
