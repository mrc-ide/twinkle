build_library <- function(name, root) {
  repo <- path_repo(root, name)
  path_provision <- file.path(repo, "provision.yml")
  dat <- yaml::read_yaml(path_provision)

  allowed <- "packages"
  extra <- setdiff(names(dat), allowed)
  if (length(extra) > 0) {
    cli::cli_abort("Unhandled configuration in provision.yml: {extra}")
  }

  path_lib <- file.path("libs", name)
  path_bootstrap <- .libPaths()[[1]]
  refs <- dat$packages

  cran <- default_cran()

  cfg <- conan2::conan_configure(
    "pkgdepends",
    refs = refs,
    cran = cran,
    path_lib = path_lib,
    path_bootstrap = path_bootstrap,
    path = root)
  conan2::conan_run(cfg)
}


default_cran <- function(repos = getOption("repos")) {
  if ("CRAN" %in% names(repos)) {
    repos[["CRAN"]]
  } else {
    "https://cloud.r-project.org"
  }
}
