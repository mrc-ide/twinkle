test_that("error if no history present", {
  root <- withr::local_tempdir()
  expect_error(history_status(root, "myapp"), "No history for 'myapp'")
})


test_that("fetch history from source update", {
  root <- withr::local_tempdir()
  sha1 <- random_sha()
  sha2 <- random_sha()
  history_update(root, "myapp", "update-src", list(sha = sha1))

  dat <- history_status(root, "myapp")
  d <- dat[["update-src"]]
  expect_equal(d$name, "myapp")
  expect_s3_class(d$time, "POSIXt")
  expect_equal(d$action, "update-src")
  expect_equal(d$data, list(sha = sha1))

  expect_null(d[["install-packages"]])
  expect_null(d[["sync-staging"]])
  expect_null(d[["sync-production"]])

  history_update(root, "myapp", "update-src", list(sha = sha2))
  expect_equal(history_status(root, "myapp")[["update-src"]]$data,
               list(sha = sha2))
})


test_that("report on package installation", {
  root <- withr::local_tempdir()
  sha1 <- random_sha()
  sha2 <- random_sha()
  lib1 <- "20240105152157"
  lib2 <- "20240105160000"
  history_update(root, "myapp", "update-src", list(sha = sha1))
  history_update(root, "myapp", "install-packages",
                 list(sha = sha1, lib = lib1))

  dat <- history_status(root, "myapp")
  d <- dat[["install-packages"]]
  expect_equal(d$name, "myapp")
  expect_s3_class(d$time, "POSIXt")
  expect_equal(d$action, "install-packages")
  expect_equal(d$data, list(sha = sha1, lib = lib1))
  expect_null(d$warning)

  history_update(root, "myapp", "update-src", list(sha = sha2))
  dat <- history_status(root, "myapp")
  d <- dat[["install-packages"]]
  expect_equal(d$data, list(sha = sha1, lib = lib1))
  expect_equal(d$warning, "Source has changed since last installation")
})


test_that("report on sync", {
  root <- withr::local_tempdir()
  sha1 <- random_sha()
  sha2 <- random_sha()
  lib1 <- "20240105152157"
  lib2 <- "20240105160000"
  history_update(root, "myapp", "update-src", list(sha = sha1))
  history_update(root, "myapp", "install-packages",
                 list(sha = sha1, lib = lib1))
  history_update(root, "myapp", "sync-staging",
                 list(sha = sha1, lib = lib1))

  dat <- history_status(root, "myapp")
  d <- dat[["sync-staging"]]
  expect_equal(d$name, "myapp")
  expect_s3_class(d$time, "POSIXt")
  expect_equal(d$action, "sync-staging")
  expect_equal(d$data, list(sha = sha1, lib = lib1))
  expect_null(d$warning)

  history_update(root, "myapp", "update-src", list(sha = sha2))
  d <- history_status(root, "myapp")[["sync-staging"]]
  expect_equal(d$data, list(sha = sha1, lib = lib1))
  expect_equal(d$warning, "Source has changed since last sync")

  history_update(root, "myapp", "install-packages",
                 list(sha = sha2, lib = lib2))

  history_update(root, "myapp", "update-src", list(sha = sha2))
  d <- history_status(root, "myapp")[["sync-staging"]]
  expect_equal(d$data, list(sha = sha1, lib = lib1))
  expect_equal(d$warning, "Source and packages have changed since last sync")

  history_update(root, "myapp", "sync-staging",
                 list(sha = sha2, lib = lib1))
  d <- history_status(root, "myapp")[["sync-staging"]]
  expect_equal(d$data, list(sha = sha2, lib = lib1))
  expect_equal(d$warning, "Packages have changed since last sync")
})
