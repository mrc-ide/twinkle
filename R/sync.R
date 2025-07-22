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


sync_app <- function(name, subdir, production, root, verbose = TRUE) {
  type <- if (production) "production" else "staging"
  cli::cli_h1("Copying {name} ({type})")
  dest <- path_app(root, name, production)
  path_lib <- path_lib(root, name)

  rsync_mirror_directory(path_src(root, name, subdir), dest,
                         exclude = c(".git", ".lib"),
                         verbose = verbose)
  rsync_mirror_directory(path_lib(root, name), file.path(dest, ".lib"),
                         exclude = ".conan",
                         verbose = verbose)

  list(sha = last_repo_id(root, name),
       lib = last_conan_id(root, name))
}
