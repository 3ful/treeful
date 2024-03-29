############ Load Packages ############ 
if(!require(librarian)) install.packages("librarian")
library(librarian)
shelf(data.table,stringr,stringdist,fuzzyjoin,dplyr)

############ Define Function for fuzzy matching ############ 
flatten_names <- function(tree_name) {
  tree_name <-  str_replace_all(tree_name," ", "") %>%
    str_replace_all(.,"\\.","") %>%
    str_replace_all(.,"\\-","") %>%
    str_replace_all(.,"\\'","") %>%
    tolower(.)
}


get_fuzzy_plant_names <- function(plant_database, master_list, max_string_dist=3){
# Prepare for matching
# Extract unique names
database_names <- plant_database[,.(latin_name=unique(latin_name))]

# Flatten names
master_list[,flat_name:=flatten_names(latin_name)]
database_names[,flat_name:=flatten_names(latin_name)]

# Match
stringdist <- as.data.table(
                stringdist_join(database_names, master_list, 
                by = c("flat_name" = "flat_name"), 
                mode = "inner", 
                method = "dl", 
                max_dist = max_string_dist, 
                distance_col = "dist"))
# Clean matching
stringdist <- stringdist[,.(data_set_name=latin_name.x,master_list_name=latin_name.y,distance=dist)]
stringdist <- setorder(stringdist,-distance)
return(stringdist)
# As an example of possible other matching functions:
# amatch <-  amatch(database_names[,flat_name], master_list[,flat_name], maxDist = 0.1)
}
############ MAIN: Create master list of botanical names ############ 
# Load datasets
# Use trees4EU as master list, more coverage
master_list <- data.table::fread("2_Data/0_raw_data/EUforestspecies_AMauri.csv") %>% 
  janitor::clean_names() %>% 
  dplyr::select(latin_name = species_name) %>% 
  distinct()
master_list <- na.omit(master_list)

############ OPEN TREES DATA BASE ############ 
# Load and prepare database

# Load database
open_trees_db <- fread("2_Data/1_output/all_merged.csv")
setnames(open_trees_db,"species","latin_name")
open_trees_db <- na.omit(open_trees_db)

# Match db names
max_string_dist = 1 
open_trees_matching_table<- get_fuzzy_plant_names(open_trees_db, master_list, max_string_dist)
open_trees_matching_table_selection <- open_trees_matching_table[distance<=1,]
# Filter database
open_trees_db_selection <- open_trees_db[open_trees_matching_table_selection[,.(data_set_name,master_list_name)], on = c(latin_name = "data_set_name"), nomatch = NULL]
# open_trees_db_selection2 <- open_trees_db[latin_name %in% open_trees_matching_table_selection[,data_set_name]]

############ TRY DATA BASE ############ 
# Load database
if (file.exists("2_Data/0_raw_data/tree_georef_3.txt")) {
  try_trees <- data.table::fread("2_Data/0_raw_data/tree_georef_3.txt") %>% 
    janitor::clean_names()
  
  setnames(try_trees,"acc_species_name","latin_name")
  try_trees <- na.omit(try_trees)
  
  
  # Match db names
  max_string_dist = 1 
  try_trees_matching_table<- get_fuzzy_plant_names(try_trees, master_list, max_string_dist)
  try_trees_matching_table_selection <- try_trees_matching_table[distance<=1,]
  # Filter database
  try_trees_selection <- try_trees[try_trees_matching_table_selection[,.(data_set_name,master_list_name)], on = c(latin_name = "data_set_name"), nomatch = NULL]
  # open_trees_db_selection2 <- open_trees_db[latin_name %in% open_trees_matching_table_selection[,data_set_name]]
  
  
} else {
  try_trees_selection <- tibble(master_list_name = character(), 
                                tree_georef_1_std_value = numeric(),
                                obs_data_std_value = numeric())
}


############ Trees4F DATA BASE ############ 
# Load and prepare database

# Load database
trees4f_db <- data.table::fread("2_Data/0_raw_data/EUforestspecies_AMauri.csv") %>% 
  janitor::clean_names()

setnames(trees4f_db,"species_name","latin_name")
trees4f_db <- na.omit(trees4f_db)

# Match db names
max_string_dist = 3 
trees4f_db_matching_table<- get_fuzzy_plant_names(trees4f_db, master_list, max_string_dist)
trees4f_db_matching_table_selection <- trees4f_db_matching_table[distance<=1,]
# Filter database
trees4f_db_selection <- trees4f_db[trees4f_db_matching_table_selection[,.(data_set_name,master_list_name)], on = c(latin_name = "data_set_name"), nomatch = NULL]
# open_trees_db_selection2 <- open_trees_db[latin_name %in% open_trees_matching_table_selection[,data_set_name]]




# enhance master list with GBIF taxo IDs and write master list to file
tree_master_list <- master_list %>% 
  mutate(gbif_taxo_id = name_backbone_checklist(name=.$latin_name)$usageKey) %>% 
  # remove  unmatched or genus level taxo matches
  filter(str_length(gbif_taxo_id) > 5 & !is.na(gbif_taxo_id))

fwrite(tree_master_list,"2_Data/1_output/eu_native_trees_master.csv")
tree_master_list <- fread("2_Data/1_output/eu_native_trees_master.csv") 


rm(open_trees_db, open_trees_matching_table, open_trees_matching_table_selection, try_trees, try_trees_matching_table, 
   try_trees_matching_table_selection, trees4f_db, trees4f_db_matching_table, trees4f_db_matching_table_selection
   )

#EOF