FROM rocker/shiny-verse:latest

# We need to install a few of these because they're required for use
# with twinkle (both git/git-lfs and rsync will be called as shell
# commands).
RUN apt-get update && apt-get install -y git git-lfs rsync \
    && rm -rf /var/lib/apt/lists/*

COPY . /src

## For some reason 'remotes::install_local("/src")' fails to copy to
## the tempdir, so working around this for now.  We also copy over the
## user Rprofile file which simplifies handling of package libraries
## to look for '.lib' in any containing directory of an application.
RUN Rscript -e 'remotes::install_deps("/src", upgrade = FALSE)' \
    && cp /src/docker/Rprofile /root/.Rprofile \
    && R CMD INSTALL "/src"
