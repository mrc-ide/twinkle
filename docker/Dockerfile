FROM rocker/shiny-verse:latest

# We need to install a few of these because they're required for use
# with twinkle (both git/git-lfs and rsync will be called as shell
# commands).
RUN apt-get update && apt-get install -y git git-lfs rsync \
    && rm -rf /var/lib/apt/lists/*

# These are additional, but as we're the only real users of the system
# that's fine. Used by various packages that our applications require.
RUN apt-get update && apt-get install -y \
    cmake \
    gdal-bin \
    libgdal-dev \
    libgeos-dev \
    libglpk-dev \
    libproj-dev \
    libudunits2-dev \
    && rm -rf /var/lib/apt/lists/*

COPY . /src

## For some reason 'remotes::install_local("/src")' fails to copy to
## the tempdir, so working around this for now.  We also copy over the
## user Rprofile file which simplifies handling of package libraries
## to look for '.lib' in any containing directory of an application.
RUN Rscript -e 'remotes::install_deps("/src", upgrade = FALSE)' \
    && R CMD INSTALL "/src" \
    && cp /src/docker/Rprofile /root/.Rprofile
