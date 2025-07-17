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
  msg <- capture_messages(twinkle_deploy_key_create("myapp"))
  expect_length(msg, 2)
  expect_match(msg[[1]], "Add the public key to github at")
  expect_true(file.exists(path_deploy_key(root, "myapp")))
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
