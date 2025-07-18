# twinkle2

<!-- badges: start -->
[![R-CMD-check](https://github.com/mrc-ide/twinkle2/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/mrc-ide/twinkle2/actions/workflows/R-CMD-check.yaml)
[![Codecov test coverage](https://codecov.io/gh/mrc-ide/twinkle2/graph/badge.svg)](https://app.codecov.io/gh/mrc-ide/twinkle2)
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

We are reasonably agnostic about how deployments are configured, and the actual configuration is fairly basic; see [`shiny-dev`](https://github.com/reside-ic/shiny-dev/tree/docker-compose) for a full example using `docker compose` and minimal configuration for the three services above.

We then imagine some persistant storage (such as a docker volume) holding all the data for applications; this is where `shiny` will serve from but also some persistant storage that we need in order to set the applications up.  The `reside-ic/twinkle2` container contains a cli application `twinkle` that can perform simple administrative commands based on a configuration that describes the applications.

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

# Packages

Applications will depend on a number of packages in order to run.  This should be indicated within the application root of the repository (so in the repository root if `subdir` is not used, or within `subdir` otherwise).  Currently we support the legacy `provision.yml` format that was used by the original DIDE shiny server.  We will describe the new format here once implemented.

The actual package installation is performed with [`pkgdepends`](https://github.com/r-lib/pkgdepends) via [`conan2`](https://github.com/mrc-ide/conan2/).

# Interaction

Here, we assume the exact setup used in [`shiny-dev`](https://github.com/reside-ic/shiny-dev/tree/docker-compose), and we assume that the system is running (i.e., `docker compose ps` shows services running).

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

We assume that two environment variables are set

* `TWINKLE_ROOT`: points at the directory where all twinkle data will be stored.  The applications to be served will be found at `${TWINKLE_ROOT}/apps` and the staging applications at `${TWINKLE_ROOT}/staging`
* `TWINKE_CONFIG`: points at the location of the configuration

In the [`shiny-dev`](https://github.com/reside-ic/shiny-dev/tree/docker-compose) setup, we set these in the compose file, bind-mounting the configuration in from the host (read-only) and using a docker volume for the root, shared among all workers.  Practicaly, the server configuration needs to kept in sync with this configuration, with `site_dir` set to `${TWINKLE_ROOT}/apps`
