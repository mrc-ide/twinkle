test_that("can clone project", {
  path <- withr::local_tempdir()
  repo_init("starmeds", "mrc-ide/starmeds", path)
  expect_true(file.exists(file.path(path, "repos", "starmeds", "app.R")))
})
