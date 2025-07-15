test_that("can clone project", {
  path <- withr::local_tempdir()
  repo_init("starmeds", "mrc-ide", "starmeds", NULL, path)
  repo <- file.path(path, "repos", "starmeds", "app.R")
  expect_true(file.exists(repo))
})


test_that("can translate provision to pkgdepends", {
  expect_equal(
    translate_provision_to_pkgdepends(
      list(packages = c("a", "b"))),
    c("a", "b"))
  expect_equal(
    translate_provision_to_pkgdepends(
      list(packages = c("a", "b"),
           package_sources = list(
             github = "foo/bar"))),
    c("a", "b", "github::foo/bar"))
})


test_that("error on unsupported provisioning fields", {
  expect_error(
    translate_provision_to_pkgdepends(
      list(package = c("a", "b"))),
    "Unhandled configuration in provision.yml: package$")
  expect_error(
    translate_provision_to_pkgdepends(
      list(packages = c("a", "b"),
           self = TRUE)),
    "Unhandled configuration in provision.yml: self$")
  expect_error(
    translate_provision_to_pkgdepends(
      list(packages = c("a", "b"),
           package_sources = list(
             list(gitlab = "foo/bar")))),
    "Unhandled package_sources")
})
