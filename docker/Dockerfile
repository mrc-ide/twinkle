FROM rocker/shiny-verse:latest

# We need to install a few of these because they're required for use
# with twinkle (both git/git-lfs and rsync will be called as shell
# commands).
RUN apt-get update && apt-get install -y git git-lfs rsync \
    && rm -rf /var/lib/apt/lists/*

RUN Rscript -e 'remotes::install_github("mrc-ide/twinkle2")'
