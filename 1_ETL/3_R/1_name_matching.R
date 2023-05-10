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
############ MAIN: example of fuzzy matching and data extraxtion############ 
# Load datasets
# Master list with all European trees
master_list <- fread("2_Data/0_raw_data/eu_native_trees.csv")
master_list <- master_list[,.(latin_name=V1)]

# # TRY Database as an example
# try_plant_db <- fread("2_Data/0_raw_data/Try_database_all_Species.txt")
# setnames(try_plant_db,"AccSpeciesName","latin_name")
# # Get fuzzy plant names
# # The function requires both tables to be data.table, and the Species name to be latin_name
# max_string_dist = 1 
# try_matching_table <- get_fuzzy_plant_names(try_plant_db, master_list, max_string_dist)
# # Now this needs to be checked manually and only proper matches need to be kept
# try_matching_table_selection <- try_matching_table[distance<=1,]
# # Now match all the species names in the TRY database names
# 
# try_db_selection <- try_plant_db[try_matching_table_selection[,.(data_set_name,master_list_name)], on = c(latin_name = "data_set_name"), nomatch = NULL]

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
# Load and prepare database

# Load database
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



rm(open_trees_db, open_trees_matching_table, open_trees_matching_table_selection, try_trees, try_trees_matching_table, 
   try_trees_matching_table_selection, trees4f_db, trees4f_db_matching_table, trees4f_db_matching_table_selection
   )

#EOF