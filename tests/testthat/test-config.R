test_that("error if configuration not found", {
  expect_error(read_config(tempfile()),
               "Configuration file '.+' not found")
})


test_that("error if configuration has unhandled keys", {
  path <- withr::local_tempfile()
  writeLines("apps: ~\nfoo: ~", path)
  expect_error(read_config(path),
               "Expected 'site.yml' to only have top-level field 'apps'")
})


test_that("error if apps is not named list", {
  path <- withr::local_tempfile()
  writeLines("apps: hello", path)
  expect_error(read_config(path),
               "Expected 'site.yml:apps' to be a named list")
})


test_that("can read an application", {
  path <- withr::local_tempfile()
  writeLines(
    c("apps:",
      "  foo:",
      "    username: bob",
      "    repo: app",
      "    branch: main"),
    path)
  dat <- read_config(path)
  expect_equal(
    dat,
    list(apps = list(foo = list(username = "bob",
                                repo = "app",
                                branch = "main",
                                name = "foo"))))
})


test_that("can validate application fields", {
  dat <- list(username = "bob",
              repo = "app",
              branch = "main",
              name = "foo")
  expect_error(
    check_app_config("foo", dat),
    "Unknown fields present in 'site.yml:apps:foo': name")
  expect_error(
    check_app_config("foo", dat[-1]),
    "Required fields missing in 'site.yml:apps:foo': username")
})
