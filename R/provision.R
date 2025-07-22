build_library <- function(name, subdir, root) {
  cli::cli_h1("Building library")
  cfg <- provision_conan_configuration(name, subdir, root)
  withr::with_dir(root, conan2::conan_run(cfg))
  list(sha = last_repo_id(root, name),
       lib = last_conan_id(root, name))
}


default_cran <- function(repos = getOption("repos")) {
  if ("CRAN" %in% names(repos)) {
    repos[["CRAN"]]
  } else {
    "https://cloud.r-project.org"
  }
}


provision_conan_configuration <- function(name, subdir, root) {
  repo <- path_src(root, name, subdir)
  dat <- provision_configuration(root, repo, name)
  rlang::inject(
    conan2::conan_configure(
      !!!dat,
      cran = default_cran(),
      path_lib = file.path("libs", name),
      path_bootstrap = .libPaths()[[1]],
      path = root))
}


provision_configuration <- function(root, path, name) {
  if (file.exists(file.path(path, "conan.R"))) {
    script <- file.path(fs::path_rel(path, root), "conan.R")
    list(method = "script", script = script)
  } else if (file.exists(file.path(path, "pkgdepends.txt"))) {
    filename <- file.path(fs::path_rel(path, root), "pkgdepends.txt")
    list(method = "pkgdepends", refs = NULL, filename = filename)
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

  packages <- unique(dat$packages)

  if (!is.null(dat$package_sources)) {
    if (!identical(names(dat$package_sources), "github")) {
      cli::cli_abort("Unhandled package_sources")
    }
    github <- sprintf("github::%s", dat$package_sources$github)
    re <- "^[^/]+/([^/@#]+).*$"
    github_packages <- sub(re, "\\1", github)
    packages <- setdiff(packages, github_packages)
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


last_conan_id <- function(root, name) {
  max(conan2::conan_list(path_lib(root, name))$name)
}
