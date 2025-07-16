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
           other = TRUE)),
    "Unhandled configuration in provision.yml: other$")
  expect_error(
    translate_provision_to_pkgdepends(
      list(packages = c("a", "b"),
           package_sources = list(
             list(gitlab = "foo/bar")))),
    "Unhandled package_sources")
})


test_that("can splice in self-installs", {
  expect_equal(
    translate_provision_to_pkgdepends(
      list(packages = c("a", "b"), self = TRUE),
      "foo"),
    c("a", "b", "local::./repos/foo"))
})


test_that("can provision a library", {
  skip_if_not_installed("mockery")
  mock_run <- mockery::mock()
  mockery::stub(build_library, "conan2::conan_run", mock_run)

  path <- withr::local_tempdir()

  path_provision <- file.path(path, "repos", "pkg", "provision.yml")
  dir_create(dirname(path_provision))
  writeLines("packages: [pkg1, pkg2, pkg3]", path_provision)
  msg <- capture_messages(build_library("pkg", NULL, path))
  expect_match(msg, "Building library", all = FALSE)

  mockery::expect_called(mock_run, 1)
  args <- mockery::mock_args(mock_run)[[1]]
  expect_length(args, 1)
  expect_equal(args[[1]],
               conan2::conan_configure(
                 "pkgdepends",
                 refs = c("pkg1", "pkg2", "pkg3"),
                 cran = default_cran(),
                 path_lib = "libs/pkg",
                 path_bootstrap = .libPaths()[[1]],
                 path = path))
})


test_that("can select default cran", {
  withr::with_options(
    list(repos = NULL),
    expect_equal(default_cran(), "https://cloud.r-project.org"))
  withr::with_options(
    list(repos = "https://cran.example.com"),
    expect_equal(default_cran(), "https://cloud.r-project.org"))
  withr::with_options(
    list(repos = c(CRAN = "https://cran.example.com")),
    expect_equal(default_cran(), "https://cran.example.com"))
  withr::with_options(
    list(repos = c(CRAN = "https://cran.example.com", "https://other.com")),
    expect_equal(default_cran(), "https://cran.example.com"))
})
