ARG SERVER_VERSION
FROM mrcide/shiny-server:${SERVER_VERSION}

RUN apt-get update && apt-get install -y apache2-utils

COPY bootstrap.R /bootstrap.R
RUN Rscript /bootstrap.R && rm /bootstrap.R

RUN ssh-keyscan github.com >> /etc/ssh/ssh_known_hosts

COPY bin /usr/local/bin
COPY common.R /usr/local/lib/shiny.R

CMD ["bash"]
