################# fetch all common trees from GBIF for a few countries ################
# this section runs through the most common trees identified in the other 3 databases (>500 occurrences)
# and fetches for each species occurrences from GBIF for select countries. 
# the goal is to enlarge the pool of climate variations.
# these are then saved on disk and later on merged into one GBIF file. 
# we only take trees that are flagged as present and with accuracy of <1000m

library(librarian)
shelf(tidyverse,
      sf, 
      rgbif, 
      data.table,
      CoordinateCleaner)

################### Get prep datasets ready #########################
# master list names of trees to query for
tree_master_list <- fread("2_Data/1_output/try_eu_native_trees_master.csv") 

tree_master_list <- tree_master_list %>% 
  mutate(gbif_taxo_id = name_backbone_checklist(name=.$name)$usageKey) %>% 
  # remove  unmatched or genus level taxo matches
  filter(str_length(gbif_taxo_id) > 5 & !is.na(gbif_taxo_id))
# 
# # this is a dumb implementation to fetch german vernacular names. does not work for all, needs refining
# for (i in 1:nrow(tree_master_list)) {
#   name_de <- name_usage(key=tree_master_list$gbif_taxo_id[i], data='vernacularNames', language = "GERMAN")$data %>%  
#     filter(language == "deu") %>% 
#     slice(1) %>% 
#     .$vernacularName
#   
#   if (is_empty(name_de)) {tree_master_list$name_de[i] <- as.character(NA)} else {tree_master_list$name_de[i] <- name_de}
#   
#   print(tree_master_list$name_de[i])
# }

    
  
  #################### Get all common trees as per master list from GBIF  ###################
  # gbif post processing: https://ropensci.github.io/CoordinateCleaner/articles/Cleaning_GBIF_data_with_CoordinateCleaner.html
  # set up GBIF creds like this https://docs.ropensci.org/rgbif/articles/gbif_credentials.html
  
  # here you can reschedule a download. according to the parameters
  # gbif_download <- occ_download(
  #   pred_in("taxonKey", tree_master_list$gbif_taxo_id),
  #   #pred("taxonKey", 5284884),
  #   # this is the bounding box of europe
  #   pred_within("POLYGON((-15 75,-15 30,40 30,40 75,-15 75))"), 
  #   pred_lt("coordinateUncertaintyInMeters",1000), #downstream processing needs 1km accuracy
  #   pred("hasCoordinate", TRUE), 
  #   pred("hasGeospatialIssue", FALSE), # remove GBIF default geospatial issues
  #   pred("occurrenceStatus","PRESENT"), 
  #   pred_gte("year", 1960), #only keep trees seen after 1960
  #   format = "SIMPLE_CSV")  
  # 
  # occ_download_wait(gbif_download) 
  # 
# we use a pre-run static download. this will not include recently added trees. 
rgbif::occ_download_get("0027501-230530130749713") %>%
    occ_download_import() %>%
    setNames(tolower(names(.))) %>% # set lowercase column names to work with CoordinateCleaner
    filter(!coordinateuncertaintyinmeters %in% c(301,3036,999,9999)) %>% 
    filter(!decimallatitude == 0 | !decimallongitude == 0) %>%
    cc_cen(buffer = 2000) %>% # remove country centroids within 2km 
    cc_cap(buffer = 2000) %>% # remove capitals centroids within 2km
    cc_inst(buffer = 2000) %>% # remove zoo and herbaria within 2km 
    cc_sea() %>% # remove from ocean, this test needs rnaturalearth dev version from github https://github.com/ropensci/rnaturalearth
    distinct(decimallongitude,decimallatitude,specieskey,datasetkey, .keep_all = TRUE) %>%
    data.table::fwrite(file = "2_Data/1_output/gbif_eu_trees.csv")