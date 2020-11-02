FROM rocker/shiny:latest

RUN apt-get update && apt-get install -y \
    git \
    libapparmor-dev \
    libcurl4-openssl-dev \
    libgdal-dev \
    libgeos-dev \
    libglpk40 \
    libhiredis-dev \
    libmagick++-dev \
    libjq-dev \
    libssl-dev \
    libudunits2-dev \
    libv8-dev \
    libxml2-dev

# This will allow the use of a per-shiny-app library path, overriding
# all other libraries
# options(repos = c(CRAN = 'https://cran.rstudio.com/'), download.file.method = 'libcurl')
RUN echo 'if (file.exists(".lib")) .libPaths(c(".lib", .libPaths()))' >> \
    /usr/local/lib/R/etc/Rprofile.site

RUN mkdir -p /shiny/logs /shiny/apps

# Override the rocker defaults with our defaults
COPY shiny-server.conf /etc/shiny-server/shiny-server.conf

# These will be replaced by our docker compose file but that's ok at
# least for now.
COPY applications /shiny/apps
