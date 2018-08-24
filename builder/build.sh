#!/usr/bin/env bash
set -e
docker build --rm --tag "mrcide/shiny-server-builder:3.5.1" .
