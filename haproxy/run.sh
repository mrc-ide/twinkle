docker run --rm -it --name myproxy \
       -v ${PWD}/haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg:ro \
       -p 80:80 \
       --network=haproxy \
       haproxy:1.7
