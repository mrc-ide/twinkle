#!/usr/bin/env bash

# This gives us two ultra simple https servers doing practically
# nothing on ports 8001 and 8002.  This script will stream logs until
# interrupted and then remove the containers.
set -e

# For debugging with nginx
# IMAGE=nginx
# PORT=80

# For running shiny
IMAGE=rocker/shiny
PORT=3838

docker run -d -p 8001:$PORT --rm --name server1 $IMAGE
docker run -d -p 8002:$PORT --rm --name server2 $IMAGE

function cleanup() {
    docker kill server1 server2
}
trap cleanup EXIT

docker logs -f --tail=30 server1 | sed -e 's/^/[-- 1 --]/' &
docker logs -f --tail=30 server2 | sed -e 's/^/[-- 2 --]/' &

sleep inf
