## shiny-server-config

Support for running a self-hosted shiny server:

* over https
* with per-application authentication
* with a global pool of load balanced replica shiny servers
* scriptable provisioning of shiny applications, including from private repositories
* integration with [`vault`](https://vaultproject.io) for secret management


### Get started

```
docker run \
  -v ${PWD}:/target \
  -w /target \
  --user="`id -u`:`id -u`" \
  mrcide/shiny-server-builder:0.0.1 \
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

where `<n>` is the number of shiny-server replicas that are wanted

### Design

The basic idea is to deviate from the general pattern of bundling an R library *into* a container, but instead to use a container to build a library and then bind-mount that into the container.  This should allow for fairly flexible deployments and live updates without having to restart containers.

Each application has its own separate isolated library, though they do share a common instance of R (so practically probably have to track the same major R version).

The `site.yml` file will describe the desired configuration, and we'll try and get the server into that state.  When running, the shiny server runs in the container as the `shiny` user, who has read/write access to a volume containing the application, library and any persistent data that the application writes.
