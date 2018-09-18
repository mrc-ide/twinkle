## example twinkle site

```
./scripts/init
./scripts/pull_images
./scripts/vault_auth
./scripts/provision_all
./scripts/sync_server
./scripts/configure_apache --self-signed
docker-compose up -d
./scripts/register_workers 1
```
