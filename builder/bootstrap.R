options(repos = c(drat = "https://mrc-ide.github.io/drat", getOption("repos")))
## For now this is kept manually in sync with the DESCRIPTION
install.packages(c(
  "docopt",
  "getPass",
  "openssl",
  "provisionr",
  "remotes",
  "shinyjs",
  "sys",
  "vaultr",
  "yaml",
  "whisker"))
