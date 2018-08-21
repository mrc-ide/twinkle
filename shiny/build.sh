#!/usr/bin/env bash
set -e
docker build --rm --tag "mrcide/shiny-server-base:3.5.1" .
