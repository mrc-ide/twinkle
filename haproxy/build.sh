#!/usr/bin/env bash
set -e
docker build --rm --tag "mrcide/haproxy:1.8" .
