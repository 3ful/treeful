#############
# This script will load various tree location data into one. 
# Goal: have all in one db with harmonized botanical species name, X and Y coordinate in EPSG 4326

if(!require(librarian)) install.packages("librarian")
library(librarian)
shelf(tidyverse, sf, osmdata, stars, raster, snow, geodata, jsonlite, readxl,janitor,data.table)



tree_dbs <- read_xlsx("2_Data/0_raw_data/opendata_trees.xlsx") %>% 
  janitor::clean_names() %>% 
  filter(suitable == "y" & epsg == "4326") %>% 
  mutate(location = janitor::make_clean_names(location)) %>% 
  mutate(botanical_col = tolower(botanical_col)) 
  # mutate(lon_col = janitor::make_clean_names(lon_col)) %>% 
  # mutate(lat_col = janitor::make_clean_names(lat_col)) 


tree_dbs <- data.table(tree_dbs)
for (i in tree_dbs[,file_name]) {
  utils::unzip(zipfile=paste("2_Data/0_raw_data/tree_cadastres/zip/",i,".zip",sep=""))
}

for (i in 1:nrow(tree_dbs)) {

  ifelse(str_detect(tree_dbs$file_name[i], "csv"),
         assign(tolower(tree_dbs$location[i]),
                janitor::clean_names(read_delim(paste0("2_Data/0_raw_data/tree_cadastres/", tree_dbs$file_name[i])))),
         assign(tolower(tree_dbs$location[i]),
                janitor::clean_names(bind_cols(jsonlite::read_json(paste0("2_Data/0_raw_data/tree_cadastres/", tree_dbs$file_name[i]), simplifyVector = TRUE)$features$properties,
                                     jsonlite::read_json(paste0("2_Data/0_raw_data/tree_cadastres/", tree_dbs$file_name[i]), simplifyVector = TRUE)$features$geometry)
                                     )
                )
  )
  print(i)
}



# # Compress all the csv files with gzip
# tree_dbs <- data.table(tree_dbs)
# for (i in tree_dbs[,file_name]) {
#      db <- fread(paste("2_Data/0_raw_data/tree_cadastres/",i,sep=""))
#      fwrite(db,paste("2_Data/0_raw_data/tree_cadastres/",i,".gz",sep=""),compress="gzip")
# }

# tree_dbs[,file_name:=paste(file_name,".gz",sep="")]
# write.xlsx2(tree_dbs, "2_Data/0_raw_data/opendata_trees.xlsx", sheetName = "Sheet1", 
#             col.names = TRUE, row.names = TRUE, append = FALSE)

# 
# tree_dbs <- data.table(tree_dbs)
# for (i in tree_dbs[,location]) {
#     print(i)
#     assign(tolower(i), paste(fread(paste("2_Data/0_raw_data/tree_cadastres/",tree_dbs[location==i,file_name],sep=""))))
# }
              
# too small data to automate. manually merge mutate
#split_species <- filter(tree_dbs, str_detect(botanical_col, "\\+"))
#mutate(tourcoing, merged_species = paste0(genre, " ", espece)) %>% write_csv(file = "data/opentrees/tourcoing.csv")

merged_geo <- filter(tree_dbs, lon_col == lat_col)
sep_geo <- filter(tree_dbs, lon_col != lat_col)


#######
# unmerge merged geographies
for (i in 1:nrow(merged_geo)) {
  temp_db <- get(tolower(merged_geo$location[i]), envir = globalenv()) %>% 
    dplyr::select(matches(paste0(merged_geo$botanical_col[i], "|", merged_geo$lon_col[i]), ignore.case = TRUE)) 
  
  temp_db <- temp_db %>% 
    separate(merged_geo$lon_col[i], into = c("x", "y"), sep = ",") %>% 
    mutate(x = str_remove(x, "c\\("), y = str_remove(y, "\\)")) %>% 
    rename(species = merged_geo$botanical_col[i])
  
  assign(tolower(merged_geo$location[i]), temp_db)
  print(i)
  print(merged_geo$location[i])
}

# treat regular lat lon sources
for (i in 1:nrow(sep_geo)) {
  temp_db <- get(tolower(sep_geo$location[i]), envir = globalenv()) %>% 
    dplyr::select(matches(paste0(sep_geo$botanical_col[i], "|", sep_geo$lon_col[i], "|", sep_geo$lat_col[i]), ignore.case = TRUE))
  
  temp_db <- temp_db %>% 
    rename(species = sep_geo$botanical_col[i], 
           x = sep_geo$lat_col[i],
           y = sep_geo$lon_col[i]
           )
  
  assign(tolower(sep_geo$location[i]), temp_db)
  print(i)
  print(sep_geo$location[i])
}

#bring it all together into one df
all_trees <- tibble()

for (i in 1:nrow(tree_dbs)) {
  temp_db <- get(tolower(tree_dbs$location[i]), envir = globalenv()) %>% 
    dplyr::select(x, y, species)
  
  temp_db <- temp_db %>% 
    mutate(x = as.numeric(x)) %>% 
    mutate(y = as.numeric(y)) %>% 
    mutate(db_city_origin = tree_dbs$location[i])
  
  assign(tolower(tree_dbs$location[i]), temp_db)
  all_trees <- bind_rows(all_trees, temp_db)
  print(i)
  print(tree_dbs$location[i])
}

all_trees_centroids <- all_trees %>% 
  st_as_sf(coords = c("y", "x"), na.fail = F) %>% 
  group_by(db_city_origin) %>% 
  summarise(st_union(geometry)) %>%
  st_centroid() 

#### save it all on disk, 4 million trees
write_csv(all_trees, "2_Data/1_output/all_merged.csv")


#"specie|especi|nom_lat|latboomsoort|espece|
#nom_cientific|wetenschappelijke_naam|classe|dendro_taxon_tid|
#  nome_scien|traeart|SPECIE|sortiment|essence_scient|gattung_lat|species|gattung|geo_point"

# all tree lists saved as csv in data folder. why csv?
# cause majority of opendata portal tree lists were in csv so its least cumbersome conversion
# also csv means less characters and therefore less data when things become very large. 


