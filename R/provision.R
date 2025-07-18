build_library <- function(name, subdir, root) {
  cli::cli_h1("Building library")
  repo <- path_src(root, name, subdir)

  dat <- provision_configuration(repo)

  cfg <- rlang::inject(
    conan2::conan_configure(
      !!!dat,
      cran = default_cran(),
      path_lib = file.path("libs", name),
      path_bootstrap = .libPaths()[[1]],
      path = root))
  withr::with_dir(root, conan2::conan_run(cfg))
}


default_cran <- function(repos = getOption("repos")) {
  if ("CRAN" %in% names(repos)) {
    repos[["CRAN"]]
  } else {
    "https://cloud.r-project.org"
  }
}


provision_configuration <- function(path) {
  if (file.exists(file.path(path, "conan.R"))) {
    list(method = "script", script = "conan.R")
  } else if (file.exists(file.path(path, "pkgdepends.txt"))) {
    list(method = "pkgdepends", refs = NULL)
  } else if (file.exists(file.path(path, "provision.yml"))) {
    cli::cli_alert_warning(
      "Translating 'provision.yml' into pkgdepends format")
    dat <- suppressWarnings(yaml::read_yaml(file.path(path, "provision.yml")))
    refs <- translate_provision_to_pkgdepends(dat, name)
    list(method = "pkgdepends", refs = refs)
  } else {
    cli::cli_abort(
      c("Did not find provisioning information",
        i = paste("Expected to find one of 'pkgdepends.txt', 'conan.R' or",
                  "'provision.yml' in '{path}'")))
  }
}


translate_provision_to_pkgdepends <- function(dat, name) {
  allowed <- c("packages", "package_sources", "self")
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

  if (isTRUE(dat$self)) {
    self <- sprintf("local::%s", path_repo(".", name))
  } else {
    self <- NULL
  }

  c(packages, github, self)
}
