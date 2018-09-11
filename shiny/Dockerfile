FROM rocker/shiny:latest

RUN apt-get update && apt-get install -y \
    git \
    libcurl4-openssl-dev \
    libmagick++-dev \
    libssl-dev \
    libxml2-dev

# This will allow the use of a per-shiny-app library path, overriding
# all other libraries
# options(repos = c(CRAN = 'https://cran.rstudio.com/'), download.file.method = 'libcurl')
RUN echo 'if (file.exists(".lib")) .libPaths(c(".lib", .libPaths()))' >> \
    /usr/local/lib/R/etc/Rprofile.site

RUN mkdir -p /shiny && chown shiny.shiny /shiny

# Override the rocker defaults with our defaults
COPY shiny-server.conf /etc/shiny-server/shiny-server.conf
COPY applications /shiny/apps
