#!/usr/bin/env bash
set -e

if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit
fi

COMPOSE_VERSION=1.22.0

if which -a docker > /dev/null; then
    echo "docker is already installed"
else
    echo "installing docker"
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
    add-apt-repository \
         "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
          $(lsb_release -cs) \
          stable"
    apt-get update
    apt-get install -y docker-ce
    if [ -z "$SUDO_USER" ]; then
        echo "Can't determine real user id"
    else
        echo "Granting docker permission to user $SUDO_USER"
        usermod -aG docker "$SUDO_USER"
    fi
fi

if which -a docker-compose > /dev/null; then
    echo "docker-compose is already installed"
else
    echo "installing docker-compose"
    curl -L \
         "https://github.com/docker/compose/releases/download/$COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m)" \
         -o /usr/bin/docker-compose
    chmod +x /usr/bin/docker-compose
fi
