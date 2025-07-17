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
