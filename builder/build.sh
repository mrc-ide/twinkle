#!/usr/bin/env bash
set -e
HERE=$(realpath $(dirname $0))
docker build --rm --tag "mrcide/shiny-server-builder:3.5.1" $HERE
