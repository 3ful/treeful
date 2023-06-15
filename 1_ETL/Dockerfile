FROM rocker/geospatial
RUN apt-get update && apt-get install -y \
    libsecret-1-dev \
    libsodium-dev
#COPY ./ /home/rstudio/
WORKDIR /home/rstudio
CMD R -e "source('./3_R/0_main.R')"
EXPOSE 8787