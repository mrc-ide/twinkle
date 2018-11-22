main_vault_auth <- function(args) {
  no_args("vault_auth", args)
  vault_auth()
  invisible()
}


main_add_deploy_key <- function(args) {
  "Usage:
  add_deploy_key [--overwrite] <repo>" -> usage
  args <- docopt::docopt(usage, args)
  add_deploy_key(args$repo, args$overwrite)
  invisible()
}


main_add_github_pat <- function(args) {
  "Usage:
  add_github_pat [--overwrite] <appname> <pat>" -> usage
  args <- docopt::docopt(usage, args)
  add_github_pat(args$appname, args$pat, args$overwrite)
  invisible()
}


main_import_ssl <- function(args) {
  "Usage:
  import_ssl <key> <cert>...
  import_ssl --self-signed" -> usage
  args <- docopt::docopt(usage, args)
  if (isTRUE(args$"--self-signed")) {
    tmp <- tempfile()
    message("Generating self-signed certificate")
    args <- write_self_signed_ssl(tmp)
  }
  message("Importing certificate into vault")
  import_ssl(args$cert, args$key)
}


main_provision_all <- function(args) {
  no_args("provision_all", args)
  provision_all()
  invisible()
}


main_provision <- function(args) {
  "Usage:
  provision [--preclean --update-source-only] <name>..." -> usage
  args <- docopt::docopt(usage, args)
  provision_apps(args$name, preclean = args$preclean,
                 update_source_only = args$"update-source-only")
  invisible()
}


main_set_password <- function(args) {
  "Usage:
  set_password <user> [<password>]"-> usage
  args <- docopt::docopt(usage, args)
  set_password(args$user, args$password)
}


main_sync_server <- function(args) {
  no_args("sync_server", args)
  sync_server()
  invisible()
}


main_sync_app <- function(args) {
  "Usage:
  sync_app <name>..." -> usage
  args <- docopt::docopt(usage, args)
  sync_apps(args$name)
  invisible()
}


main_configure_apache <- function(args) {
  "Usage:
  configure_apache [options]

  --self-signed      use a self signed certificate
  --port-http=PORT   port to use for http
  --port-https=PORT  port to use for https
  --port-admin=PORT  port to use for admin
  --port-stats=PORT  port to use for statistics" -> usage
  args <- docopt::docopt(usage, args)
  configure_apache(".", args$"self-signed", args$port_http, args$port_https,
                   args$port_admin, args$port_stats)
  invisible()
}


main_update_users <- function(args) {
  no_args("update_users", args)
  update_users()
  invisible()
}


main_vault_auth <- function(args) {
  no_args("vault_auth", args)
  vault_auth()
  invisible()
}


main_init <- function(args) {
  no_args("init", args)
  init()
  invisible()
}


main_write_schedule <- function(args) {
  "Usage:
  write_schedule <dest>" -> usage
  args <- docopt::docopt(usage, args)
  write_schedule(args$dest)
  invisible()
}


no_args <- function(name, args) {
  usage <- sprintf("Usage:\n  %s", name)
  docopt::docopt(usage, args)
}
