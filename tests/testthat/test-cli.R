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
  cli(args = c("sync", "myapp"))
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


test_that("cli_delete args work", {
  skip_if_not_installed("mockery")
  mock_run <- mockery::mock()
  mockery::stub(cli, "twinkle_delete_app", mock_run)
  cli(args = c("delete", "myapp"))
  mockery::expect_called(mock_run, 1)
  args <- mockery::mock_args(mock_run)[[1]]
  expect_equal(args, list("myapp"))
})


test_that("can create a deploy key with the cli", {
  skip_if_not_installed("mockery")
  mock_deploy_key <- mockery::mock()
  mockery::stub(cli, "twinkle_deploy_key", mock_deploy_key)
  cli(args = c("deploy-key", "myapp"))
  mockery::expect_called(mock_deploy_key, 1)
  expect_equal(mockery::mock_args(mock_deploy_key)[[1]],
               list("myapp", recreate = FALSE))
})


test_that("can call cli deploy", {
  skip_if_not_installed("mockery")
  mock_deploy <- mockery::mock()
  mockery::stub(cli, "twinkle_deploy", mock_deploy)
  cli(args = c("deploy", "myapp"))
  mockery::expect_called(mock_deploy, 1)
  expect_equal(mockery::mock_args(mock_deploy)[[1]], list("myapp", FALSE))
})


test_that("can list applications through the cli", {
  skip_if_not_installed("mockery")
  mock_list <- mockery::mock(c("a", "b"))
  mockery::stub(cli, "twinkle_list", mock_list)
  out <- capture_output(cli(args = "list"))
  mockery::expect_called(mock_list, 1)
  expect_equal(mockery::mock_args(mock_list)[[1]], list(NULL))
  expect_equal(out, "a\nb")
})


test_that("can restart applications through the cli", {
  skip_if_not_installed("mockery")
  mock_restart <- mockery::mock()
  mockery::stub(cli, "twinkle_restart", mock_restart)
  out <- cli(args = c("restart", "foo"))
  mockery::expect_called(mock_restart, 1)
  expect_equal(mockery::mock_args(mock_restart)[[1]], list("foo"))
})


test_that("install cli script works", {
  path <- withr::local_tempdir()
  install_cli(path)
  f <- file.path(path, "twinkle")
  expect_true(file.exists(f))
  d <- readLines(f)
  expect_equal(length(d), 2)
})
