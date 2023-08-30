FROM rocker/verse:4.2.2
RUN apt-get update && apt-get install -y  gdal-bin libcairo2-dev libcurl4-openssl-dev libfribidi-dev libgdal-dev libgeos-dev libgeos++-dev libharfbuzz-dev libicu-dev libpng-dev libpq-dev libproj-dev libssl-dev libtiff-dev libudunits2-dev libxml2-dev make pandoc zlib1g-dev && rm -rf /var/lib/apt/lists/*
RUN mkdir -p /usr/local/lib/R/etc/ /usr/lib/R/etc/
RUN echo "options(repos = c(CRAN = 'https://cran.rstudio.com/'), download.file.method = 'libcurl', Ncpus = 4)" | tee /usr/local/lib/R/etc/Rprofile.site | tee /usr/lib/R/etc/Rprofile.site
RUN R -e 'install.packages("remotes")'
RUN Rscript -e 'remotes::install_version("tibble",upgrade="never", version = "3.2.1")'
RUN Rscript -e 'remotes::install_version("htmltools",upgrade="never", version = "0.5.5")'
RUN Rscript -e 'remotes::install_version("cachem",upgrade="never", version = "1.0.8")'
RUN Rscript -e 'remotes::install_version("DBI",upgrade="never", version = "1.1.3")'
RUN Rscript -e 'remotes::install_version("ggplot2",upgrade="never", version = "3.4.2")'
RUN Rscript -e 'remotes::install_version("raster",upgrade="never", version = "3.6-23")'
RUN Rscript -e 'remotes::install_version("markdown",upgrade="never", version = "1.7")'
RUN Rscript -e 'remotes::install_version("shiny",upgrade="never", version = "1.7.4.1")'
RUN Rscript -e 'remotes::install_version("purrr",upgrade="never", version = "1.0.1")'
RUN Rscript -e 'remotes::install_version("dplyr",upgrade="never", version = "1.1.2")'
RUN Rscript -e 'remotes::install_version("tidyr",upgrade="never", version = "1.3.0")'
RUN Rscript -e 'remotes::install_version("data.table",upgrade="never", version = "1.14.8")'
RUN Rscript -e 'remotes::install_version("RPostgreSQL",upgrade="never", version = "0.7-5")'
RUN Rscript -e 'remotes::install_version("leaflet",upgrade="never", version = "2.1.2")'
RUN Rscript -e 'remotes::install_version("config",upgrade="never", version = "0.3.1")'
RUN Rscript -e 'remotes::install_version("testthat",upgrade="never", version = "3.1.10")'
RUN Rscript -e 'remotes::install_version("spelling",upgrade="never", version = "2.2.1")'
RUN Rscript -e 'remotes::install_version("wesanderson",upgrade="never", version = "0.3.6")'
RUN Rscript -e 'remotes::install_version("waiter",upgrade="never", version = "0.2.5")'
RUN Rscript -e 'remotes::install_version("shinythemes",upgrade="never", version = "1.2.0")'
RUN Rscript -e 'remotes::install_version("shinyFeedback",upgrade="never", version = "0.4.0")'
RUN Rscript -e 'remotes::install_version("sf",upgrade="never", version = "1.0-14")'
RUN Rscript -e 'remotes::install_version("RPostgres",upgrade="never", version = "1.4.5")'
RUN Rscript -e 'remotes::install_version("rpostgis",upgrade="never", version = "1.4.4")'
RUN Rscript -e 'remotes::install_version("pool",upgrade="never", version = "1.0.1")'
RUN Rscript -e 'remotes::install_version("paletteer",upgrade="never", version = "1.5.0")'
RUN Rscript -e 'remotes::install_version("leaflet.extras",upgrade="never", version = "1.0.0")'
RUN Rscript -e 'remotes::install_version("hrbrthemes",upgrade="never", version = "0.8.0")'
RUN Rscript -e 'remotes::install_version("golem",upgrade="never", version = "0.4.1")'
RUN Rscript -e 'remotes::install_version("ggtext",upgrade="never", version = "0.1.2")'
RUN Rscript -e 'remotes::install_version("DT",upgrade="never", version = "0.28")'
RUN Rscript -e 'remotes::install_version("tidyverse",upgrade="never", version = "2.0.0")'
RUN Rscript -e 'remotes::install_version("xfun",upgrade="never", version = "0.40")'
RUN Rscript -e 'remotes::install_version("bslib",upgrade="never", version = "0.5.0")'
ARG CACHE_DATE=2023-08-22
RUN mkdir /home/rstudio/treeful/
COPY ./ /home/rstudio/treeful/
COPY treeful_*.tar.gz /app.tar.gz
#RUN R -e 'remotes::install_local("/app.tar.gz",upgrade="never")'
#RUN rm /app.tar.gz
WORKDIR /home/rstudio/treeful/
EXPOSE 3838
#install needs to happen on run, otherwise install fails since docker secrets are not mounted
CMD  ["R", "-e", "options('shiny.port'=3838,shiny.host='0.0.0.0');remotes::install_local('/app.tar.gz',upgrade='never');library(treeful);treeful::run_app()"]
