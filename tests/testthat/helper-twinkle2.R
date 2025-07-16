create_simple_git_repo <- function(path) {
  gert::git_init(path)
  gert::git_config_set("user.name", "user", repo = path)
  gert::git_config_set("user.email", "user@example.com", repo = path)
  writeLines(letters, file.path(path, "data"))
  gert::git_add(".", repo = path)
  gert::git_commit("first", repo = path)
}
