init <- function(target = ".") {
  version <- packageVersion("twinkle")
  dir.create(target, FALSE, TRUE)
  init_ignore(target)
  init_site_yml(target, version)
  init_scripts(target, version)
  message("Initialised!")
}


init_ignore <- function(target) {
  paths <- c(".vault", "apache", "docker-compose.yml", "restart.txt",
             "scripts")
  target_gitignore <- file.path(target, ".gitignore")
  if (file.exists(target_gitignore)) {
    prev <- readLines(target_gitignore)
  } else {
    prev <- character()
  }
  write_if_changed(union(prev, paths), target_gitignore, collapse = TRUE)
}


init_site_yml <- function(target, version) {
  target_site_yml <- file.path(target, "site.yml")
  if (file.exists(target_site_yml)) {
    message("'site.yml' already exists")
  } else {
    dat <- list(twinkle_version = version)
    site_yml_template <- read_string(twinkle_file("site.yml.in"))
    write_if_changed(whisker::whisker.render(site_yml_template, dat),
                     target_site_yml)
    target_hello <- file.path(target, "local/hello")
    if (file.exists(target_hello)) {
      message("'local/hello' already exists")
    } else {
      dir.create(target_hello, FALSE, TRUE)
      hello <- dir(twinkle_file("hello"), full.names = TRUE)
      file.copy(hello, target_hello, recursive = TRUE)
    }
  }
}


init_scripts <- function(target, version) {
  message("Updating scripts")
  dir.create(file.path(target, "scripts"), FALSE, TRUE)

  scripts <- dir(twinkle_file("scripts"), full.names = TRUE)
  dest <- file.path(target, "scripts")
  dir.create(dest, FALSE, TRUE)
  dat <- list(twinkle_version = version)
  for (s in scripts) {
    write_if_changed(whisker::whisker.render(read_string(s), dat),
                     file.path(dest, basename(s)))
  }
  Sys.chmod(file.path(dest, basename(scripts)), "755")
  extra <- setdiff(dir(dest), basename(scripts))
  if (length(extra) > 0L) {
    message("Removing obsolete scripts: %s",
            paste(extra, collapse = ", "))
    unlink(file.path(dest, extra))
  }
}
