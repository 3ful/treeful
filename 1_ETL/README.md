# ETL

* Run preprocessing to obtain tree cadastres 
* Run main to harmonize names and fetch bioclimatic variables for all tree locations. 

## Prerequisites

* Hardware requirements: 
  * especially the GBIF dataset is large and memory intensive with 7 million occurrences. You probably need over 8GB RAM to run this. 
  * Copernicus raster files are also large, the VM should have over 100GB disk space. 
* You must create the following credential files in 0_secrets directory
  * copernicus_key.txt
  * copernicus_uid.txt
  * gbif_email.txt
  * gbif_pw.txt
  * gbif_uid.txt
  * keyring_pw.txt
  * postgres_pw.txt
  
## How does this work

* with docker compose up two containers will be spun up: 
  * the ETL container is based on rocker/geospatial and runs through the 0_main.R script: fetching tree locations from various sources, name matching them and finally getting bioclimatic variables for each tree location out fo Copernicus raster files. This container will take a few hours to run and then shut itself down. 
  * the Postgres container is the receiver of the raster data and the final database of tree locations and correspnding bioclimatic variables. This container will be exposed to the frontend. 

## Data sources used

* Tree databases
  * Open Tree cadastres: from the EU data portal as many consumable tree cadastres as possible were found
  * GBIF
  * TRY: restricted. 
  * Trees4F
* Historic Bioclimatic variables
* Projected future bioclimatic variables

```
GBIF_USER="your-gbif-user"
GBIF_PWD="your-gbif-pw"
GBIF_EMAIL="your-gbif-mail"
COPERNICUS_KEY="your-copernicus-key"
COPERNICUS_UID="your-copernicus-UID"
POSTGRES_PW="your-postgres-pw"

```