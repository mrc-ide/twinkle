configure_apache <- function(path = ".", self_signed = NULL,
                             port_http = NULL, port_https = NULL,
                             port_admin = NULL) {
  dat <- read_site_yml(path)

  port_http <- port_http %||% dat$server$port_http %||% 80L
  port_https <- port_https %||% dat$server$port_https %||% 443L
  port_admin <- port_admin %||% dat$server$port_admin %||% 9000L
  self_signed <- self_signed %||% dat$server$self_signed %||% FALSE
  twinkle_tag <- dat$twinkle_tag

  ## There are three things that we need to do here perhaps:
  ##
  ## 1. update httpd.conf
  ## 2. update ssl
  ## 3. update users
  ## 4. update docker-compose.yml (ports)

  reload <- update_httpd_conf(path, dat$server$hostname, dat$server$email,
                              port_http, port_https, port_admin)
  update_httpd_ssl(path, self_signed)
  update_users(path, dat)
  update_httpd_compose(path, twinkle_tag, port_http, port_https, port_admin)
}


update_httpd_conf <- function(path, hostname, email, port_http, port_https,
                              port_admin) {
  path_httpd_conf <- file.path(path, "apache/httpd.conf")
  dir.create(dirname(path_httpd_conf), FALSE, TRUE)
  dat <- list(hostname = hostname,
              email = email,
              port_http = port_http,
              port_https = port_https,
              port_admin = port_admin)
  template <- read_string(twinkle_file("httpd.conf.in"))
  str <- whisker::whisker.render(template, dat)
  write_if_changed(str, path_httpd_conf)
}


update_httpd_ssl <- function(path, self_signed) {
  path_ssl <- file.path(path, "apache/ssl")
  dir.create(path_ssl, FALSE, TRUE)
  if (self_signed) {
    write_self_signed_ssl(path_ssl)
  } else {
    export_ssl(path_ssl)
  }
}


update_users <- function(path = ".", dat = NULL) {
  dat <- dat %||% read_site_yml(path)
  template <- read_string(twinkle_file("auth.conf.in"))
  path_auth <- file.path(path, "apache/auth")
  dir.create(path_auth, FALSE, TRUE)

  if (!is.null(dat$groups)) {
    vault_root <- Sys.getenv("VAULT_ROOT")
    vault <- vaultr::vault_client(quiet = TRUE)

    user_keys <- vault$list(sprintf("%s/users", vault_root))

    used <- unique(unlist(dat$groups, FALSE, FALSE))
    unk <- setdiff(used, basename(user_keys))
    if (length(unk) > 0L) {
      stop("Unknown users: %s", paste(unk, collapse = ", "))
    }

    users <- vapply(user_keys, vault$read, "", field = "password",
                    USE.NAMES = FALSE)

    groups <- vapply(dat$groups, paste, "", collapse =  " ")
    groups <- sprintf("%s: %s", names(dat$groups), unname(groups))
  } else {
    users <- groups <- character(0)
  }

  groups_used <- lapply(dat$apps, function(x) x$groups)
  groups_used <- groups_used[lengths(groups_used) > 0L]

  unk <- setdiff(unlist(groups_used, FALSE, FALSE),
                 names(dat$groups))
  if (length(unk) > 0L) {
    stop("Unknown groups: %s", paste(unk, collapse = ", "))
  }

  write_auth_conf <- function(app) {
    dest <- sprintf("%s/%s.conf", path_auth, gsub("/", "_", app$path))
    value <- sprintf(template, app$path, paste(app$groups, collapse = " "))
    write_if_changed(value, dest)
    dest
  }

  conf <- vapply(dat$app[names(groups_used)], write_auth_conf, "")
  extra <- setdiff(dir(path_auth, pattern = "\\.conf$", full.names = TRUE),
                   conf)
  unlink(extra)

  write_if_changed(users, file.path(path_auth, "users"), TRUE)
  write_if_changed(groups, file.path(path_auth, "groups"), TRUE)
}


update_httpd_compose <- function(path, twinkle_tag, port_http, port_https,
                                 port_admin) {
  template <- read_string(twinkle_file("docker-compose.yml.in"))
  dat <- list(twinkle_tag = twinkle_tag,
              port_http = port_http,
              port_https = port_https,
              port_admin = port_admin)
  str <- whisker::whisker.render(template, dat)
  write_if_changed(str, file.path(path, "docker-compose.yml"))
}


export_ssl <- function(path = ".") {
  vault_root <- Sys.getenv("VAULT_ROOT")
  vault <- vaultr::vault_client(quiet = TRUE)
  dat <- vault$read(vault_path_ssl(vault_root))

  cert <- file.path(path, "certificate.pem")
  key <- file.path(path, "key.pem")

  message("Writing ssl certificate")
  message(sprintf("  - key: '%s'", key))
  message(sprintf("  - cert: '%s'", cert))
  write_if_changed(dat$cert, cert)
  write_if_changed(dat$key, key)
}


import_ssl <- function(cert, key) {
  if (length(cert) < 1L) {
    stop("Expected at least one certificate")
  }
  cert <- vapply(cert, read_string, "")
  key <- read_string(key)
  vault_root <- Sys.getenv("VAULT_ROOT")
  vault <- vaultr::vault_client(quiet = TRUE)
  vault$write(vault_path_ssl(vault_root), list(cert = cert, key = key))
}


write_self_signed_ssl <- function(path) {
  dir.create(path, FALSE, TRUE)
  key <- file.path(path, "key.pem")
  cert <- file.path(path, "certificate.pem")
  message("Writing self signed ssl certificate")
  message(sprintf("  - key: '%s'", key))
  message(sprintf("  - cert: '%s'", cert))

  data <- c(C = "UK",
            ST = "London",
            O = "DIDE",
            localityName = "London",
            commonName = "testing.dide.ic.ac.uk",
            organizationalUnitName = "DIDE",
            emailAddress = "admin@example.com")
  subj <- sprintf(
    "/%s/",
    paste(sprintf("%s=%s", names(data), unname(data)), collapse = "/"))
  args <- c("req", "-batch", "-subj", subj, "-newkey", "rsa:2048",
            "-nodes", "-x509", "-days 365",
            "-keyout", key, "-out", cert)
  system3("openssl", args, check = TRUE)
  list(key = key, cert = cert)
}


set_password <- function(user, password = NULL) {
  vault_root <- Sys.getenv("VAULT_ROOT")
  password <- password %||% trimws(getPass::getPass("Password: "))
  vault_path <- sprintf("%s/users/%s", vault_root, user)

  dest <- tempfile()
  tmp <- system3("htpasswd", c("-cbB", dest, user, password),
                 check = TRUE, output = FALSE)
  value <- readLines(dest)
  unlink(dest)

  vault <- vault_client()
  vault$write(vault_path, list(password = value))
  invisible(value)
}


verify_password <- function(username, password, passwordfile) {
  res <- system3("htpasswd", c("-bv", passwordfile, username, password),
                 check = FALSE, output = FALSE)
  res$success
}


read_groups <- function(groupfile) {
  groups <- strsplit(readLines(groupfile), ":\\s+")
  members <- strsplit(vcapply(groups, "[[", 2L), "\\s+")
  names(members) <- vcapply(groups, "[[", 1L)
  members
}


user_membership <- function(username, groupfile) {
  groups <- read_groups(groupfile)
  i <- vapply(groups, function(x) username %in% x, logical(1))
  names(groups)[i]
}


read_users <- function(passwordfile) {
  sub(":.*", "", readLines(passwordfile))
}


update_user_password <- function(username, password, passwordfile) {
  hash <- set_password(username, password)
  prev <- readLines(passwordfile)
  new <- sprintf("%s:%s", username, hash)
  writeLines(c(prev[grepl("^username:", prev)], new),
             passwordfile)
}
