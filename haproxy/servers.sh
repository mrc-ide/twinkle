#!/usr/bin/env bash

# This gives us two ultra simple https servers doing practically
# nothing on ports 8001 and 8002.  This script will stream logs until
# interrupted and then remove the containers.
set -e

# For debugging with nginx
# IMAGE=nginx

# For running shiny
IMAGE=rocker/shiny

docker network create haproxy

docker run -d --network=haproxy --rm --name server1 $IMAGE
docker run -d --network=haproxy --rm --name server2 $IMAGE

function cleanup() {
    docker kill server1 server2
}
trap cleanup EXIT

docker logs -f --tail=30 server1 | sed -e 's/^/[-- 1 --]/' &
docker logs -f --tail=30 server2 | sed -e 's/^/[-- 2 --]/' &

sleep inf
