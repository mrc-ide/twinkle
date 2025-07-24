# twinkle

<!-- badges: start -->
[![R-CMD-check](https://github.com/mrc-ide/twinkle/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/mrc-ide/twinkle/actions/workflows/R-CMD-check.yaml)
[![Codecov test coverage](https://codecov.io/gh/mrc-ide/twinkle/graph/badge.svg)](https://app.codecov.io/gh/mrc-ide/twinkle)
<!-- badges: end -->

`twinkle` is a package designed to help manage a set of shiny applications.  The package itself does not actually contain any shiny-specific code but mostly helps:

* fetch code from github (possibly from a private repository)
* build application-specific libraries so that each app runs in relative isolation
* synchronise the app sources and library into directory trees that can contain both staging and "production" instances

# Usage

Our primary use of this system is as a docker container as part of a deployment acting as a *load balanced shiny server*.  To do this, we have three services:

```
<apache> -- <haproxy> -- <shiny...>
```

where `apache` presents the interface to the world and looks after https, `haproxy` acts as a load balancer and we have several (one to many) copies of `shiny`, each capable of serving every application.

We like this setup, compared with something like [shinyproxy](https://shinyproxy.io/) where balancing occurs **between applications** but multiple users of the same appliation compete (this at least [used to be the case](https://support.openanalytics.eu/t/more-than-one-user-per-container/373)).  In our experience, multiple users tend to correlate on the **same** application, e.g., when running a workshop or after launching an app related to a new publication.

We are reasonably agnostic about how deployments are configured, and the actual configuration is fairly basic; see [`shiny-dev`](https://github.com/reside-ic/shiny-dev) for a full example using `docker compose` and minimal configuration for the three services above.

We then imagine some persistant storage (such as a docker volume) holding all the data for applications; this is where `shiny` will serve from but also some persistant storage that we need in order to set the applications up.  The `reside-ic/twinkle` container contains a cli application `twinkle` that can perform simple administrative commands based on a configuration that describes the applications.

# Configuration

The configuration is in yaml, and the only valid top-level key is `apps`.  This is a list of objects, each representing an application with the name being the anme of the application.  A simple configuration would look like:

```
apps:
  myapp:
    username: alice
    repo: alices-app
    branch: main
```

which contains a single application that will be served at `/myapp`, which we will find at `github.com/alice/alices-app`

The valid fields within each application are:

* `username` (required): the github user or organisational name that holds the sources
* `repo` (required): the name of the repository within the `username` namespace on github
* `branch`: optionally the branch to deploy.  By default we will use the default branch from github (i.e., the one that you see when you navigate to the github landing page and the branch that is checked out by default on clone)
* `subdir`: the subdirectory within the repo where the application itself can be found.  It is reasonably common that the application might be found somewhere other than the root; packages often use `inst/app` and sometimes a shiny app is part of a larger repository.  The application can be stored anywhere within the repo, but it may not reference files above the subdirectory while it runs
* `private`: a boolean indicating if the repository is private. If so, you will need to add a deploy key to the repository in order to clone it over ssh
* `script`: an optional script to run after the app has been sync-ed to the destination (either staging or production).

The intention for use of `script` is for apps that are installed into a directory that is read-only at app runtime, which is the case in [`shiny-dev`](https://github.com/reside-ic/shiny-dev) so that we can safely run many workers on the same tree.  This causes issues where it is convenient to have the code in the application perform some calculation after cloning but before running.  Examples that we have seen where this was used (or could have been used) are:

* downloading some data that is not able to be stored in the git repository
* prerending rmarkdown for use with `learnr`

Note that (at least at present) this script is run separately after the sync to staging and to production, so ideally the script should be deterministic or you will see slightly different results.  It is possible that we could change things to allow sync to production to occur from staging (rather from the sources) but that requires that we always update source/lib, then staging, then production.

# Packages

Applications will depend on a number of packages in order to run.  This should be indicated within the application root of the repository (so in the repository root if `subdir` is not used, or within `subdir` otherwise).

Most applications can use the same `pkgdepends.txt` format that is supported by [`conan`](https://mrc-ide.github.io/conan/), as used in [`hipercow`](https://mrc-ide.github.io/hipercow/articles/packages.html).  See [the docs here](https://mrc-ide.github.io/hipercow/articles/packages.html#using-pkgdepends) for details.  Typically this is simply a file `pkgdepends.txt` in the application root, with each line being the name of a package or a github specification like `mrc-ide/malariasimulation@v1.6.0`, for example:

```
# Also use the mrc-ide universe
repo::https://mrc-ide.r-universe.dev

# Specific version of malaria simulation, via a tag
mrc-ide/malariasimulation@v1.6.0

# Package from CRAN
coda
```

The actual package installation is performed with [`pkgdepends`](https://github.com/r-lib/pkgdepends).

Alternatively, you can use a script `conan.R` and install packages within that however you want.  This is useful for cases where pkgdepends is failing to resolve things and you need to manually override bits of dependency resolution that is failing to get right.

Finally, we support legacy `provision.yml` files used with the original shiny server, but as we don't want new projects to use this method we do not describe it.  There is no pressing need to migrate old projects, however.

The precedence order is `conan.R` (highest precedence), then `pkgdepends.txt`, then `provision.yml` (lowest precedence).

# Interaction

Here, we assume the exact setup used in [`shiny-dev`](https://github.com/reside-ic/shiny-dev), and we assume that the system is running (i.e., `docker compose ps` shows services running).

You should be able to run

```
$ ./twinkle --help
Twinkle.

Usage:
  twinkle create-deploy-key [--force] <name>
  twinkle update-src [--branch=NAME] <name>
  twinkle install-packages <name>
  twinkle sync [--production] <name>
  twinkle deploy [--production] <name>
  twinkle list [<pattern>]
  twinkle delete <name>

Options:
  --branch=NAME   Github branch to use
```

which will show available commands, mapping on to the various steps in deployment.  From here, you can:

* `create-deploy-key`: create a deploy key for a private application; this generates and saves the private key within the persistant storage, then prints the public key and instructions for adding this to github.  Once you have completed this step you can clone private repositories
* `update-src`: refresh the server copy of the application source code
* `install-packages`: install packages for the application
* `sync`: push the (updated) copies of the application source and packages onto the staging directory or the live copy of the application

The other commands are helpers:

* `deploy` is a wrapper around `update-src`, `install-packages` and `sync`, designed to use when setting up a new application where you want to iterate quickly
* `list` lists known applications
* `delete` removes all files associated with an application

# Other comments

We assume that three environment variables are set

* `TWINKLE_ROOT`: points at the directory where all twinkle data will be stored.  The applications to be served will be found at `${TWINKLE_ROOT}/apps` and the staging applications at `${TWINKLE_ROOT}/staging`
* `TWINKLE_LOGS`: points at the location that the logs will be written
* `TWINKLE_CONFIG`: points at the location of the configuration

In the [`shiny-dev`](https://github.com/reside-ic/shiny-dev) setup, we set these in the compose file, bind-mounting the configuration in from the host and using a docker volume for the root, shared among all workers.  Practicaly, the server configuration needs to kept in sync with this configuration, with `site_dir` set to `${TWINKLE_ROOT}/apps`
