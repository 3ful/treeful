# ETL

* Run preprocessing to obtain tree cadastres 
* Run main to harmonize names and fetch bioclimatic variables for all tree locations. 

## Prerequisites

* You must set Env variables for API keys. Use `usethis::edit_r_environ()` and restart your r session. 
```
GBIF_USER="your-gbif-user"
GBIF_PWD="your-gbif-pw"
GBIF_EMAIL="your-gbif-mail"
COPERNICUS_KEY="your-copernicus-key"

```