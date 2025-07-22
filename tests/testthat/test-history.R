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


test_that("can render empty source information", {
  expect_message(history_status_render_update_src(NULL),
                 "Package source never updated")
})


test_that("can render real source information", {
  sha <- "f0f59031666998ffc7e37c4c2994cf5c"
  time <- structure(1753121341.34682, class = c("POSIXct", "POSIXt"))
  info <- list(data = list(sha = sha), time = time)
  expect_message(
    history_status_render_update_src(info),
    "Package source at 'f0f59031', updated 2025-07-21")
})


test_that("can render empty package installation information", {
  expect_message(history_status_render_install_packages(NULL),
                 "Library never updated")
})


test_that("can render real installation information", {
  sha <- "f0f59031666998ffc7e37c4c2994cf5c"
  lib <- "20240105152157"
  time <- structure(1753121341.34682, class = c("POSIXct", "POSIXt"))
  info <- list(data = list(sha = sha, lib = lib), time = time)
  expect_message(
    history_status_render_install_packages(info),
    "Packages installed at 2025-07-21")

  info$warning <- "Some warning"
  expect_message(
    history_status_render_install_packages(info),
    "Packages installed at 2025-07-21.+ \\(Some warning\\)")
})


test_that("can render empty deploy information", {
  expect_message(history_status_render_sync(NULL, "production"),
                 "Never deployed to production")
})


test_that("can render real deploy information", {
  time <- structure(1753121341.34682, class = c("POSIXct", "POSIXt"))
  info <- list(data = list(), time = time)
  expect_message(
    history_status_render_sync(info, "production"),
    "Deployed to production at 2025-07-21")

  info$warning <- "Some warning"
  expect_message(
    history_status_render_sync(info, "staging"),
    "Deployed to staging at 2025-07-21.+ \\(Some warning\\)")
})
