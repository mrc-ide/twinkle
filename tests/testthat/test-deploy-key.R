test_that("can write a deploy key", {
  path <- withr::local_tempfile()
  deploy_key_generate(path)
  expect_true(file.exists(path))
  expect_true("-----BEGIN PRIVATE KEY-----" %in% readLines(path))
  expect_equal(file.info(path)$mode, as.octmode("600"))
})


test_that("can create a deploy key", {
  root <- withr::local_tempfile()
  msg <- capture_messages(
    deploy_key_create("app", "user", "repo", FALSE, root))
  expect_length(msg, 2)
  expect_match(
    msg[[1]],
    "https://github.com/user/repo/settings/keys/new")
  expect_match(msg[[2]], "^ssh-rsa ")
})


test_that("Don't overwrite keys without force", {
  root <- withr::local_tempfile()
  suppressMessages(
    deploy_key_create("app", "user", "repo", FALSE, root))
  key <- readLines(path_deploy_key(root, "app"))
  expect_error(
    deploy_key_create("app", "user", "repo", FALSE, root),
    "Deploy key for 'app' already exists")
  expect_equal(readLines(path_deploy_key(root, "app")), key)
  suppressMessages(
    deploy_key_create("app", "user", "repo", TRUE, root))
  expect_false(identical(readLines(path_deploy_key(root, "app")), key))
})
