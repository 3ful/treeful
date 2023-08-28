if(!require(librarian)) install.packages("librarian")
library(librarian)
shelf(data.table,stringr, sf, tidyverse, raster, 
      paletteer, RSQLite, RPostgreSQL, DBI, fuzzyjoin, keyring, janitor, rgbif, ecmwfr, CoordinateCleaner, 
      osmdata, stars, snow, geodata, jsonlite, readxl, 
      rpostgis, terra, rvest, blastula)

# setting docker secrets as env variables to be availabe to R scripts
Sys.setenv("COPERNICUS_KEY" = read_lines("/run/secrets/copernicus_key"))
Sys.setenv("COPERNICUS_UID" = read_lines("/run/secrets/copernicus_uid"))
Sys.setenv("GBIF_EMAIL" = read_lines("/run/secrets/gbif_email"))
Sys.setenv("GBIF_PWD" = read_lines("/run/secrets/gbif_pw"))
Sys.setenv("GBIF_USER" = read_lines("/run/secrets/gbif_uid"))
Sys.setenv("POSTGRES_PW" = read_lines("/run/secrets/postgres_pw"))
Sys.setenv("POSTGRES_HOST" = read_lines("/run/secrets/postgres_host"))
Sys.setenv("POSTGRES_DB" = "treeful-test")


##### short fun for postgres connnect
backend_con <- function() {
  
  con <- DBI::dbConnect(RPostgres::Postgres(), 
                        dbname = Sys.getenv("POSTGRES_DB"),
                        host= Sys.getenv("POSTGRES_HOST"), 
                        port="5432",
                        user="postgres",
                        password=Sys.getenv("POSTGRES_PW"))
  return(con)
}

### short fun for sending ETL updates


sendstatus <- function(message = "status") {
  
  email <- 
    compose_email(
      header = "Status Update",
      body = md(
        c("##", message)
      )
    )
  smtp_send(
    email = email,
    from = "nuc@toph.eu",
    to = "chris@toph.eu",
    credentials = creds_file("0_secrets/blastula.json")
  )
}  



