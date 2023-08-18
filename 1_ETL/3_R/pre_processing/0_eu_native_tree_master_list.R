############ Load Packages ############ 
if(!require(librarian)) install.packages("librarian")
library(librarian)
shelf(data.table,stringr, rgbif)

############ Flatten Latin tree name function ############ 
# To match the names it is better to completely flatten the strings
flatten_names <- function(tree_name) {
  tree_name <-  str_replace_all(tree_name," ", "") %>%
    str_replace_all(.,"\\.","") %>%
    str_replace_all(.,"\\-","") %>%
    str_replace_all(.,"\\'","") %>%
    tolower(.)
}

############  Load tree lists ############ 
# This is the list of native European trees it combines two sources
# This is Wikipedia list https://en.wikipedia.org/wiki/Category:Trees_of_Europe
# Plus EU stuff https://forest.jrc.ec.europa.eu/en/european-atlas/atlas-download-page/
# Those were just copied by hand and the latter was cut off using reg-ex "^[^-]+"
eu_trees <- fread("2_Data/0_raw_data/eu_native_trees.csv")
eu_trees <- eu_trees[,.(eu_trees=V1)]
eu_trees[,flat_name:=flatten_names(eu_trees)]
# Load all TRY data bank species with its id and observation
# The list can be found here https://www.try-db.org/dnld/TryAccSpecies.txt
try_species <- fread("2_Data/0_raw_data/Try_database_all_Species.txt")
try_species <- try_species[,.(id=AccSpeciesID,name=AccSpeciesName,flat_name=flatten_names(AccSpeciesName),obsv=ObsNum)]

############ Create master tree list ############ 
# Now match all the species names in the TRY database names
tree_master_list <- try_species[flat_name %in% eu_trees[,flat_name]]
# Sort by most observed trees
tree_master_list <- setorder(tree_master_list,-obsv)

tree_master_list <- master_list %>% 
  mutate(gbif_taxo_id = name_backbone_checklist(name=.$latin_name)$usageKey) %>% 
  # remove  unmatched or genus level taxo matches
  filter(str_length(gbif_taxo_id) > 5 & !is.na(gbif_taxo_id))

fwrite(tree_master_list,"2_Data/1_output/try_eu_native_trees_master.csv")
tree_master_list <- fread("2_Data/1_output/try_eu_native_trees_master.csv") 



#EOF