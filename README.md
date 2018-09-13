## shiny-server-config

```
docker run \
  -v ${PWD}:/target \
  -w /target \
  --user="`id -u`:`id -u`" \
  mrcide/shiny-server-builder:0.0.1 \
  init
```
