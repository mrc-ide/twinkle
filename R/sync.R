rsync_mirror_directory <- function(from, to, exclude = NULL) {
  args <- rsync_mirror_directory_args(from, to, exclude)
  dir_create(dirname(to))
  system2_or_throw("rsync", args)
}


rsync_mirror_directory_args <- function(from, to, exclude) {
  if (!is.null(exclude)) {
    exclude <- c(rbind(rep("--exclude", length(exclude)), exclude))
  }
  c("-auv", exclude, "--delete",
    add_trailing_slash(from),
    add_trailing_slash(to))
}


sync_app <- function(name, subdir, staging, root) {
  type <- if (staging) "staging" else "production"
  cli::cli_h1("Copying {name} ({type})")
  dest <- if (staging) path_app_staging(root, name) else path_app(root, name)
  path_lib <- path_lib(root, name)

  rsync_mirror_directory(path_src(root, name, subdir), dest,
                         exclude = c(".git", ".lib", ".Rprofile"))
  rsync_mirror_directory(path_lib(root, name), file.path(dest, ".lib"),
                         exclude = ".conan")
  writeLines('.libPaths(".lib")', file.path(dest, ".Rprofile"))
}
