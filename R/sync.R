rsync_mirror_directory <- function(from, to, exclude = NULL, verbose = TRUE) {
  args <- rsync_mirror_directory_args(from, to, exclude)
  dir_create(dirname(to))
  system2_or_throw("rsync", args, verbose = verbose)
}


rsync_mirror_directory_args <- function(from, to, exclude) {
  if (!is.null(exclude)) {
    exclude <- c(rbind(rep("--exclude", length(exclude)), exclude))
  }
  c("-auv", exclude, "--delete",
    add_trailing_slash(from),
    add_trailing_slash(to))
}


sync_app <- function(name, subdir, staging, root, verbose = TRUE) {
  type <- if (staging) "staging" else "production"
  cli::cli_h1("Copying {name} ({type})")
  dest <- path_app(root, name, staging)
  path_lib <- path_lib(root, name)

  rsync_mirror_directory(path_src(root, name, subdir), dest,
                         exclude = c(".git", ".lib", ".Rprofile"),
                         verbose = verbose)
  rsync_mirror_directory(path_lib(root, name), file.path(dest, ".lib"),
                         exclude = ".conan",
                         verbose = verbose)
  writeLines('.libPaths(".lib")', file.path(dest, ".Rprofile"))
}
