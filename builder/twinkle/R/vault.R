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

  cl <- vaultr::vault_client("github", addr = address, gh_token = gh_token)

  ## There are two ways of getting the token out easily here, but one
  ## should be added to vault directly I think
  token <- cl$token$headers[[1]]
  ## cl$.get("/auth/token/lookup-self")$data$id

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
