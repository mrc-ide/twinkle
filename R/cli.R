cli <- function(args = commandArgs(TRUE)) {
  "Twinkle.
  
Usage:
  twinkle deploy-key [--recreate] <name>
  twinkle update-src [--branch=NAME] <name>
  twinkle install-packages <name>
  twinkle sync [--production] <name>
  twinkle deploy [--production] <name>
  twinkle restart <name>
  twinkle status <name>
  twinkle list [<pattern>]
  twinkle delete [--production] <name>
  twinkle logs [--list | --filename=FILENAME] <name>
" -> doc

  dat <- docopt::docopt(doc, args)
  if (dat[["deploy-key"]]) {
    twinkle_deploy_key(dat$name, recreate = dat$recreate)
  } else if (dat[["update-src"]]) {
    twinkle_update_src(dat$name, branch=dat$branch)
  } else if (dat[["install-packages"]]) {
    twinkle_install_packages(dat$name)
  } else if (dat[["sync"]]) {
    twinkle_sync(dat$name, dat[["production"]])
  } else if (dat[["restart"]]) {
    twinkle_restart(dat$name)
  } else if (dat[["status"]]) {
    twinkle_status(dat$name)
  } else if (dat[["delete"]]) {
    twinkle_delete_app(dat$name, dat$production)
  } else if (dat[["deploy"]]) {
    twinkle_deploy(dat$name, dat$production)
  } else if (dat[["list"]]) {
    writeLines(twinkle_list(dat$pattern))
  } else if (dat[["logs"]]) {
    writeLines(twinkle_logs(dat$name, dat[["--list"]], dat$filename))
  }
  invisible()
}


install_cli <- function(path) {
  code <- c("#!/usr/bin/env Rscript",
            "twinkle2:::cli()")
  path_bin <- file.path(path, "twinkle")
  writeLines(code, path_bin)
  Sys.chmod(path_bin, "755")
  invisible(path_bin)
}
