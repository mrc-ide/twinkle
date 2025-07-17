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

# Avoid rate limits building images without being able to easily add
# the github token:
RUN install2.r --error \
    --repos https://p3m.dev/cran/__linux__/noble/latest \
    --repos https://mrc-ide.r-universe.dev \
    cli \
    conan2 \
    gert \
    openssl \
    pkgdepends \
    withr \
    yaml \
    && R CMD INSTALL "/src" \
    && cp /src/docker/Rprofile /root/.Rprofile
