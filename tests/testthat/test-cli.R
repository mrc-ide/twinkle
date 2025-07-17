test_that("cli_update_src args work", {
  skip("rewrite")
  skip_if_not_installed("mockery")
  mock_run <- mockery::mock()
  mockery::stub(cli_main, "twinkle_update_app", mock_run)
  cli_main(args = c("update-src", "myapp", "--branch", "mybranch"))
  mockery::expect_called(mock_run, 1)
  args <- mockery::mock_args(mock_run)[[1]]
  expect_equal(args, list(
    name = "myapp", 
    clone_repo = TRUE, 
    install_packages = FALSE,
    update_staging = FALSE,
    update_production = FALSE, 
    branch = "mybranch"))
})


test_that("cli_install_packages args work", {
  skip("rewrite")
  skip_if_not_installed("mockery")
  mock_run <- mockery::mock()
  mockery::stub(cli_main, "twinkle_update_app", mock_run)
  cli_main(args = c("install-packages", "myapp"))
  mockery::expect_called(mock_run, 1)
  args <- mockery::mock_args(mock_run)[[1]]
  expect_equal(args, list(
    name = "myapp", 
    clone_repo = FALSE, 
    install_packages = TRUE,
    update_staging = FALSE,
    update_production = FALSE, 
    branch = NULL))
})


test_that("cli_sync args work for staging", {
  skip("rewrite")
  skip_if_not_installed("mockery")
  mock_run <- mockery::mock()
  mockery::stub(cli_main, "twinkle_update_app", mock_run)
  cli_main(args = c("sync", "myapp", "--staging"))
  mockery::expect_called(mock_run, 1)
  args <- mockery::mock_args(mock_run)[[1]]
  expect_equal(args, list(
    name = "myapp", 
    clone_repo = FALSE, 
    install_packages = FALSE,
    update_staging = TRUE,
    update_production = FALSE, 
    branch = NULL))
})


test_that("cli_sync args work for production", {
  skip("rewrite")
  skip_if_not_installed("mockery")
  mock_run <- mockery::mock()
  mockery::stub(cli_main, "twinkle_update_app", mock_run)
  cli_main(args = c("sync", "myapp", "--production"))
  mockery::expect_called(mock_run, 1)
  args <- mockery::mock_args(mock_run)[[1]]
  expect_equal(args, list(
    name = "myapp", 
    clone_repo = FALSE, 
    install_packages = FALSE,
    update_staging = FALSE,
    update_production = TRUE, 
    branch = NULL))
})


