FROM rocker/geospatial
RUN apt-get update && apt-get install -y \
    libsecret-1-dev \
    libsodium-dev
#COPY ./ /home/rstudio/
WORKDIR /home/rstudio

RUN R -e "install.packages(c('librarian'), repos='https://cloud.r-project.org/')"
RUN R -e "librarian::shelf(data.table,stringr, sf, tidyverse, raster, paletteer, RSQLite, RPostgreSQL, DBI, fuzzyjoin, keyring, janitor, rgbif, ecmwfr, CoordinateCleaner, osmdata, stars, snow, geodata, jsonlite, readxl, rpostgis)"

CMD R -e "source('./1_ETL/3_R/0_main.R')"
EXPOSE 8787