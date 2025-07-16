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
