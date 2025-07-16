create_simple_git_repo <- function(path, subdir = NULL) {
  gert::git_init(path)
  gert::git_config_set("user.name", "user", repo = path)
  gert::git_config_set("user.email", "user@example.com", repo = path)
  base <- if (is.null(subdir)) path else file.path(path, subdir)
  dir_create(base)
  fs::file_copy(system_file("hello.R", package = "twinkle2"),
                file.path(base, "app.R"))
  gert::git_add(".", repo = path)
  gert::git_commit("first", repo = path)
}


create_dummy_library <- function(root, name) {
  path <- path_lib(root, name)
  dest <- file.path(path, "pkg", "file")
  dir_create(dirname(dest))
  file.create(dest)
}


system_file <- function(...) {
  system.file(..., mustWork = TRUE)
}
