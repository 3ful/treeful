FROM rocker/geospatial

COPY ./ /home/rstudio/
WORKDIR /home/rstudio
CMD R -e "source('./3_R/0_main.R')"
EXPOSE 8787