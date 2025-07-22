create_simple_git_repo <- function(path, subdir = NULL) {
  gert::git_init(path)
  gert::git_config_set("user.name", "user", repo = path)
  gert::git_config_set("user.email", "user@example.com", repo = path)
  base <- if (is.null(subdir)) path else file.path(path, subdir)
  dir_create(base)
  fs::file_copy(system_file("hello.R", package = "twinkle"),
                file.path(base, "app.R"))
  gert::git_add(".", repo = path)
  gert::git_commit("first", repo = path)
}


create_dummy_library <- function(root, name) {
  path <- path_lib(root, name)
  dest <- file.path(path, "pkg", "file")
  dir_create(dirname(dest))
  file.create(dest)
  dir_create(file.path(path, ".conan"))
  d <- readRDS("example-conan-installation.rds")
  name <- "20240105152157"
  saveRDS(d, file.path(path, ".conan", name))
  name
}


system_file <- function(...) {
  system.file(..., mustWork = TRUE)
}


random_sha <- function() {
  paste(sample(c(0:9, letters[1:6]), 32, replace = TRUE), collapse = "")
}
