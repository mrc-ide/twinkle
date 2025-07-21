FROM rocker/shiny-verse:latest

# We need to install a few of these because they're required for use
# with twinkle (both git/git-lfs and rsync will be called as shell
# commands).
RUN apt-get update && apt-get install -y \
    curl \
    git \
    git-lfs \
    rsync \
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
    libsodium-dev \
    libudunits2-dev \
    && rm -rf /var/lib/apt/lists/*

# Expect that people will probably use quarto in the future, so let's
# install that too
RUN curl -LO https://quarto.org/download/latest/quarto-linux-amd64.deb \
    && dpkg --install quarto-linux-amd64.deb \
    && rm -f quarto-linux-amd64.deb

# We could allow use of a minimal LaTeX distribution too; this would
# install the distibution within the shiny user's directories and
# should make it available.  However, it will add another 200MB to an
# already fairly-large image.
# RUN sudo -u shiny -H Rscript -e 'tinytex::install_tinytex()'

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
    && Rscript -e 'twinkle2:::install_cli("/usr/local/bin")' \
    && cp /src/docker/Rprofile /home/shiny/.Rprofile
