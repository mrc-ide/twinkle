deploy_key_create <- function(name, username, repo, force, root) {
  path <- path_deploy_key(root, name)
  if (file.exists(path) && !force) {
    cli::cli_abort("Deploy key for '{name}' already exists")
  }
  deploy_key_generate(path)
  deploy_key_show_instructions(name, username, repo, root)
}


deploy_key_pubkey <- function(name, root) {
  path <- path_deploy_key(root, name)
  key <- openssl::read_key(path)
  openssl::write_ssh(key, NULL)
}


deploy_key_generate <- function(path) {
  dir_create(dirname(path))
  openssl::write_pem(openssl::rsa_keygen(), path)
  Sys.chmod(path, "600")
}


deploy_key_show_instructions <- function(name, username, repo, root) {
  pub <- deploy_key_pubkey(name, root)
  url_key <- sprintf("https://github.com/%s/%s/settings/keys/new",
                     username, repo)
  cli::cli_alert_info(
    "Add the public key to github at: {.url {url_key}} with content:")
  cli::cli_verbatim(pub)
}
