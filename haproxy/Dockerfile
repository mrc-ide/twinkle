FROM haproxy:1.8
RUN apt-get update && apt-get install -y \
  socat
COPY bin /usr/local/bin
COPY haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg
