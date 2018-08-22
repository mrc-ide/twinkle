#!/usr/bin/env bash
set -e

DOMAIN=development.dide.ic.ac.uk
SUBJ="
C=UK
ST=London
O=DIDE
localityName=London
commonName=$DOMAIN
organizationalUnitName=DIDE
emailAddress=admin@example.com
"

mkdir -p ssl
openssl req \
        -batch \
        -subj "$(echo -n "$SUBJ" | tr "\n" "/")" \
        -newkey rsa:2048 \
        -nodes \
        -keyout ssl/key.pem \
        -x509 \
        -days 365 \
        -out ssl/certificate.pem
