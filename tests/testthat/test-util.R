test_that("error if executable not found on path", {
  expect_error(sys_which("unknown-exe-really"),
               "Executable 'unknown-exe-really' was not found on $PATH",
               fixed = TRUE)
})


test_that("can find executable on path", {
  expect_equal(sys_which("make"), unname(Sys.which("make")))
})


test_that("can add a trailing slash to a string", {
  expect_equal(add_trailing_slash("foo"), "foo/")
  expect_equal(add_trailing_slash("foo/"), "foo/")
  expect_equal(add_trailing_slash("foo//"), "foo//")
  expect_equal(add_trailing_slash("foo/bar"), "foo/bar/")
  expect_equal(add_trailing_slash("foo/bar/"), "foo/bar/")
})


test_that("can run a command, failing if it does not succeed", {
  expect_no_error(system2_or_throw("true", character()))
  expect_error(system2_or_throw("false", character()),
               "Command failed with exit code 1")
})


test_that("can run a command, failing if it does not succeed", {
  expect_no_error(system2_or_throw("true", character()))
  expect_error(system2_or_throw("false", character()),
               "Command failed with exit code 1")
})


test_that("throw if script not found", {
  tmp <- withr::local_tempdir()
  filename <- "script.R"

  expect_error(
    run_script(tmp, filename),
    "Did not find script 'script\\.R' \\(within '.+'\\)")
})


test_that("can run a script", {
  mock_run <- mockery::mock()
  mockery::stub(run_script, "system2_or_throw", mock_run)

  tmp <- withr::local_tempdir()

  filename1 <- "script.R"
  file.create(file.path(tmp, filename1))

  run_script(tmp, filename1)
  mockery::expect_called(mock_run, 1)
  expect_equal(mockery::mock_args(mock_run)[[1]],
               list(find_rscript(), "script.R", verbose = TRUE))

  filename2 <- "script"
  file.create(file.path(tmp, filename2))

  run_script(tmp, filename2)
  mockery::expect_called(mock_run, 2)
  expect_equal(mockery::mock_args(mock_run)[[2]],
               list("./script", character(), verbose = TRUE))
})


test_that("can require an environment variable is present", {
  withr::with_envvar(c(FOO = NA_character_, BAR = "hello"), {
    expect_error(sys_getenv("FOO"),
                 "Expected environment variable 'FOO' to be set")
    expect_equal(sys_getenv("BAR"), "hello")
  })
})


test_that("dir_create works recursively and silently", {
  path <- tempdir()
  withr::with_path(path, dir_create(file.path(path, "potato/guru")))
  expect_true(file.exists(file.path(path, "potato")))
  expect_true(file.exists(file.path(path, "potato", "guru")))
  expect_silent(
    withr::with_path(path, dir_create(file.path(path, "potato/guru"))))
})

test_that("Null switch works", {
  expect_equal((NULL %||% 2), 2)
  expect_equal((3 %||% 2), 3)
})
