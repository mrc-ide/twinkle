FROM rocker/shiny:3.5.1

# This will allow the use of a per-shiny-app library path, overriding
# all other libraries
RUN echo 'if (file.exists("lib")) .libPaths(c("lib", .libPaths()))' >> \
    /usr/local/lib/R/etc/Rprofile.site

# Override the rocker defaults with our defaults
COPY shiny-server.conf /etc/shiny-server/shiny-server.conf
COPY applications /shiny/apps
