test_that("can construct arguments to sync directory", {
  expect_equal(
    rsync_mirror_directory_args("a", "b", NULL),
    c("-auv", "--delete", "a/", "b/"))
  expect_equal(
    rsync_mirror_directory_args("a/", "b/", c("x", "y")),
    c("-auv", "--exclude", "x", "--exclude", "y", "--delete","a/", "b/"))
})
