## shiny-server-config

Support for running a self-hosted shiny server:

* over https
* with per-application authentication
* with a global pool of load balanced replica shiny servers
* scriptable provisioning of shiny applications, including from private repositories
* integration with [`vault`](https://vaultproject.io) for secret management

### How does it look?

A simple configuration is included here:

- [configuration](example/site.yml)
- [instructions](example/README.md)

A more complicated example (for which this was developed) is in the [`shiny_dide`](https://github.com/mrc-ide/shiny_dide) repository.

### Get started

```
docker run \
  --rm \
  -v ${PWD}:/target \
  -w /target \
  --user="`id -u`:`id -u`" \
  mrcide/shiny-server-builder:0.0.2 \
  init
```

### Workflow

Configure everything with

```
./scripts/pull_images
./scripts/vault_auth
./scripts/provision_all
./scripts/sync_server
./scripts/configure_apache
```

Bring up the system with

```
docker-compose up -d --scale shiny=<n>
./scripts/register_workers <n>
```

where `<n>` is the number of shiny-server replicas that are wanted.

Because the core of the system, the directory name you pick is important - the containers and volumes will be named based on it.  There is not currently support for modifying this (e.g., with `--project-name`) because we need to interact with persistent volumes, and one task requires exec access to a container.  This will hopefully be relieved in future if it becomes a real annoyance.

### Design

The basic idea is to deviate from the general pattern of bundling an R library *into* a container, but instead to use a container to build a library and then bind-mount that into the container.  This should allow for fairly flexible deployments and live updates without having to restart containers.

Each application has its own separate isolated library, though they do share a common instance of R (so practically probably have to track the same major R version).

The `site.yml` file will describe the desired configuration, and we'll try and get the server into that state.  When running, the shiny server runs in the container as the `shiny` user, who has read/write access to a volume containing the application, library and any persistent data that the application writes.

For all but the most trivial cases a copy of [`vault`](https://vaultproject.io) is needed to hold secrets.  Our setup is in the [`mrc-ide-vault`](https://github.com/mrc-ide/mrc-ide-vault) repository.  Using vault means we can keep sensitive data out of the configuration.
