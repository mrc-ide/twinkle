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
