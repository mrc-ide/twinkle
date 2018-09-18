ARG SERVER_VERSION
FROM mrcide/shiny-server:${SERVER_VERSION}

RUN apt-get update && apt-get install -y \
  apache2-utils \
  python3-pip

RUN pip3 install yacron

COPY bootstrap.R /bootstrap.R
RUN Rscript /bootstrap.R && rm /bootstrap.R

RUN ssh-keyscan github.com >> /etc/ssh/ssh_known_hosts

COPY twinkle /twinkle
RUN R CMD INSTALL twinkle && \
  cp /twinkle/bin/* /usr/local/bin/ && \
  rm -rf /twinkle

RUN rm -rf /shiny/apps/*
COPY admin /shiny/apps

ENTRYPOINT ["/usr/local/bin/twinkle"]
