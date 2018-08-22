#!/usr/bin/env bash
UID=`id -u`
GID=`id -g`
docker run --rm \
       --user="${UID}:${GID}" \
       -v ${PWD}/auth:/auth \
       httpd:2.4 \
       htpasswd -cb /auth/users rich rich
