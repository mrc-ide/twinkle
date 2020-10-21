vault_path_ssl <- function(root) {
  sprintf("%s/ssl", root)
}


vault_env_str <- function(dat) {
  if (is.null(dat$vault)) {
    return(character())
  }

  address <- dat$vault$address
  root <- dat$vault$root %||% "/secret/shiny"

  gh_token <- Sys.getenv("VAULT_AUTH_GITHUB_TOKEN", "")
  if (nzchar(gh_token)) {
    message("Using GitHub token found from host environment")
  } else {
    gh_token <- trimws(getPass::getPass("Enter GitHub token: "))
  }

  cl <- vaultr::vault_client("github", addr = address, token = gh_token)

  token <- cl$api()$token

  env <- c(VAULT_ADDR = address,
           VAULTR_AUTH_METHOD = "token",
           VAULT_TOKEN = token,
           VAULT_ROOT = root)

  sprintf('%s=%s', names(env), unname(env))
}


vault_auth <- function(path = ".") {
  dat <- read_site_yml(path)
  env <- vault_env_str(dat)
  writeLines(env, file.path(path, ".vault"))
}


vault_client <- function() {
  vaultr::vault_client(quiet = TRUE, login = "token")
}
