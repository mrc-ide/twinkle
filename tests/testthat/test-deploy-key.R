test_that("can write a deploy key", {
  path <- withr::local_tempfile()
  deploy_key_generate(path)
  expect_true(file.exists(path))
  expect_true("-----BEGIN PRIVATE KEY-----" %in% readLines(path))
  expect_equal(file.info(path)$mode, as.octmode("600"))
})


test_that("can create a deploy key", {
  root <- withr::local_tempfile()
  deploy_key_create("app", FALSE, root)
  key <- readLines(path_deploy_key(root, "app"))

  deploy_key_create("app", FALSE, root)
  expect_identical(readLines(path_deploy_key(root, "app")), key)

  deploy_key_create("app", TRUE, root)
  expect_false(identical(readLines(path_deploy_key(root, "app")), key))
})


test_that("can print instructions for using a deploy key", {
  root <- withr::local_tempfile()
  deploy_key_create("app", FALSE, root)
  msg <- capture_messages(
    pub <- deploy_key_show_instructions("app", "user", "repo", root))
  expect_length(msg, 2)
  expect_match(
    msg[[1]],
    "https://github.com/user/repo/settings/keys/new")
  expect_equal(trimws(msg[[2]]), pub)
})
