FROM mrcide/shiny-server-base:3.5.1
COPY bootstrap.R /bootstrap.R
RUN Rscript /bootstrap.R && rm /bootstrap.R

COPY bin /usr/local/bin
COPY common.R /usr/local/lib/shiny.R

CMD ["bash"]
