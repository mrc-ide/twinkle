FROM haproxy:1.8
RUN apt-get update && apt-get install -y \
  socat
COPY add_server /usr/local/bin
