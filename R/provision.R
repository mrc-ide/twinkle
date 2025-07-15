build_library <- function(name, root) {
  cli::cli_h1("Building library")
  repo <- path_repo(root, name)

  ## Eventually we might want to prefer pkgdepends.txt as the
  ## installation mechanism, but that will require some logic around
  ## selecting the required installation approach based on the repo.
  path_provision <- file.path(repo, "provision.yml")
  dat <- yaml::read_yaml(path_provision)
  refs <- translate_provision_to_pkgdepends(dat)

  path_lib <- file.path("libs", name)
  path_bootstrap <- .libPaths()[[1]]

  cran <- default_cran()

  cfg <- conan2::conan_configure(
    "pkgdepends",
    refs = refs,
    cran = cran,
    path_lib = path_lib,
    path_bootstrap = path_bootstrap,
    path = root)
  withr::with_dir(root, conan2::conan_run(cfg))
}


default_cran <- function(repos = getOption("repos")) {
  if ("CRAN" %in% names(repos)) {
    repos[["CRAN"]]
  } else {
    "https://cloud.r-project.org"
  }
}


translate_provision_to_pkgdepends <- function(dat) {
  allowed <- c("packages", "package_sources")
  extra <- setdiff(names(dat), allowed)
  if (length(extra) > 0) {
    cli::cli_abort("Unhandled configuration in provision.yml: {extra}")
  }

  packages <- dat$packages

  if (!is.null(dat$package_sources)) {
    if (!identical(names(dat$package_sources), "github")) {
      cli::cli_abort("Unhandled package_sources")
    }
    github <- sprintf("github::%s", dat$package_sources$github)
  } else {
    github <- NULL
  }

  c(packages, github)
}
