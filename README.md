## shiny-server-config

```
docker run \
  -v ${PWD}:/target \
  --user=`id -u` \
  mrcide/shiny-server-builder:v0.0.1 \
  init
```
