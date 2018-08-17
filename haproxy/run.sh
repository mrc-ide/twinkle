docker run --rm -it --name myproxy \
       -v ${PWD}/haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg:ro \
       --network=host \
       haproxy:1.7
