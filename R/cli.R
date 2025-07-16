cli_main <- function(args = commandArgs(TRUE)) {

'Twinkle.
  
Usage:
  twinkle.R update-src <name> [--branch=<branch>]
  twinkle.R install-packages <name>
  twinkle.R sync <name> [--production | --staging]
  
Options:
  --branch=<branch>   Github branch to use
' -> doc

  dat <- docopt::docopt(doc, args)
  if (dat[["update-src"]]) {
    twinkle_update_app(name = dat[["name"]],
                   clone_repo = TRUE,
                   install_packages = FALSE,
                   update_staging = FALSE,
                   update_production = FALSE,
                   branch = dat[["branch"]])
  
  } else if (dat[["install-packages"]]) {
    twinkle_update_app(name = dat[["name"]],
                   clone_repo = FALSE,
                   install_packages = TRUE,
                   update_staging = FALSE,
                   update_production = FALSE,
                   branch = NULL)
  
  } else if (dat[["sync"]]) {
    twinkle_update_app(name = dat[["name"]],
                   clone_repo = FALSE,
                   install_packages = FALSE,
                   update_staging = dat[["staging"]],
                   update_production = dat[["production"]],
                   branch = NULL)
  }
}
