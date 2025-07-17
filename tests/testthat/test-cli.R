test_that("cli_update_src args work", {
  skip_if_not_installed("mockery")
  mock_run <- mockery::mock()
  mockery::stub(cli, "twinkle_update_src", mock_run)
  cli(args = c("update-src", "myapp", "--branch", "mybranch"))
  mockery::expect_called(mock_run, 1)
  args <- mockery::mock_args(mock_run)[[1]]
  expect_equal(args, list(
    "myapp", 
    branch = "mybranch"))
})


test_that("cli_install_packages args work", {
  skip_if_not_installed("mockery")
  mock_run <- mockery::mock()
  mockery::stub(cli, "twinkle_install_packages", mock_run)
  cli(args = c("install-packages", "myapp"))
  mockery::expect_called(mock_run, 1)
  args <- mockery::mock_args(mock_run)[[1]]
  expect_equal(args, list("myapp"))
})


test_that("cli_sync args work for staging", {
  skip_if_not_installed("mockery")
  mock_run <- mockery::mock()
  mockery::stub(cli, "twinkle_sync", mock_run)
  cli(args = c("sync", "myapp", "--staging"))
  mockery::expect_called(mock_run, 1)
  args <- mockery::mock_args(mock_run)[[1]]
  expect_equal(args, list("myapp", TRUE))
})


test_that("cli_sync args work for production", {
  skip_if_not_installed("mockery")
  mock_run <- mockery::mock()
  mockery::stub(cli, "twinkle_sync", mock_run)
  cli(args = c("sync", "myapp", "--production"))
  mockery::expect_called(mock_run, 1)
  args <- mockery::mock_args(mock_run)[[1]]
  expect_equal(args, list("myapp", FALSE))
})


test_that("install cli script works", {
  path <- tempdir()
  withr::with_path(path, install_cli(path))
  f <- file.path(path, "twinkle")
  expect_true(file.exists(f))
  d <- readLines(f)
  expect_equal(length(d), 2)
})
