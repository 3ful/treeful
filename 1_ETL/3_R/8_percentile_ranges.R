# This script createss percentile ranges for each tree spcies

###################################################################################################
# EXTRA LONG
# Load libraries
if(!require(librarian)) install.packages("librarian")
library(librarian)
shelf(data.table,stringr, sf,ggplot2,moments)

# Load data, extract list of tree names
trees <- fread("2_Data/1_output/tree_db.csv") %>% dplyr::select(-geometry)
tree_names <- unique(trees[,master_list_name,])
tree_names
bioclim_vars <- colnames(trees)
bioclim_vars <- bioclim_vars[3:length(bioclim_vars)]


number_of_trees <- length(tree_names)
number_of_vars <- length(bioclim_vars)

percentile_ranges  <- data.table(matrix(nrow = 0, ncol = 4))
colnames(percentile_ranges) <- c("species","bioclim_variable","centile","value")

for (i in 1:number_of_trees) {
  tree <- tree_names[i]
  print(tree)

  for (j in 1:number_of_vars) {
    # Select single species and bioclimatic variable from all the data
    bioclim_var <- bioclim_vars[j]
    print(bioclim_var)
    data <- na.omit(trees[master_list_name==tree_names[i], ..bioclim_var])
    colnames(data) <- "bioclim"
    
    # Calculate absolute distance to mean
    data[,mean_distance:=abs(bioclim-mean(bioclim, na.rm = TRUE))]
    setorder(data, cols = "mean_distance")
    number_of_observations <- nrow(data)/100
    # Fill with percentiles
    for (k in c(1:100)) {
      
      percentile=round(number_of_observations*k) # 100. quintile encompasses 100% of observation it is thus 0% good for growth
      # Upper bound
      row <-  
      # Upper bound
      percentile_ranges <- rbind(percentile_ranges,
                                 data.table(species=tree,
                                            bioclim_variable=bioclim_var,
                                            centile=k,
                                            value=max(data[1:percentile,bioclim])))
      # Lower bound
      percentile_ranges <- rbind(percentile_ranges,
                                 data.table(species=tree,
                                            bioclim_variable=bioclim_var,
                                            centile=k*-1,
                                            value=min(data[1:percentile,bioclim])))
      
      
      
    }
    
    
    
  }
}


# Write this into the data base:
fwrite(percentile_ranges,"2_Data/1_Output/all_percentile_ranges_extra_long.csv")


# percentile_ranges <- fread("2_Data/1_Output/all_percentile_ranges_extra_wide.csv")
# # Extract the whole line for the tree and bioclim and then rank it like this:
# tree <- "Abies alba"
# 
# 
# 
# bioclim_var <- "bio01_copernicus_1979_2018" 100-88 = 22%
# 
# 
# SELECT 1
# 
# TREE= VARIABLE= SORT CLOSES 
# 
# 
# tree bioclim percentile range
# alba bio01 -100:100     271k
# 
# 
# input= 271
# 
# SELECT TOP 1 * FROM percentiles 
# WHERE Name = 'Alba' and bio01 = "bio01_1972"
# ORDER BY ABS( range - @input ) 
# 
# tree bioclim percentile range
# alba bio01   -88   271k
# 
# 100-88= 22% 
# 
# 
# 
# 
# test_temp <- 281.11
# 
# 
# 
# 
# 
# # Either do this locally or do a SQL request which is similiar to this
# tree_observations <- percentile_ranges[species==tree,]
# tree_and_bioclom_observations <- tree_observations[bioclim==bioclim_var,]
# tree_and_bioclom_observations <- tree_and_bioclom_observations[1,3:ncol(tree_and_bioclom_observations)]
# centile <- as.integer(which.min(abs(tree_and_bioclom_observations - test_temp)))
# 
# # -1 numbers is lower bound upper 
# # 100. quintile encompasses 100% of observation it is thus 0% good for growth
# if (centile > 100) {centile <- centile-100}
# 
# ranking_in_percent = 101 - centile
# 




# centile noch umdrehen, dannn plotten mit data sets
###################################################################################################
###################################################################################################
###################################################################################################
###################################################################################################
###################################################################################################
###################################################################################################
# # EXTRA WIDE
# # Load libraries
# if(!require(librarian)) install.packages("librarian")
# library(librarian)
# shelf(data.table,stringr, sf,ggplot2,moments)
# 
# # Load data, extract list of tree names
# trees <- fread("~/Downloads/tree_db.csv")
# tree_names <- unique(trees[,master_list_name,])
# tree_names
# bioclim_vars <- colnames(trees)
# bioclim_vars <- bioclim_vars[3:length(bioclim_vars)]
# 
# 
# percentile_ranges <- as.data.frame(matrix(0, ncol=102, nrow=0, dimnames=list(NULL,paste0(-102:-1))))
# percentile_ranges <- cbind(percentile_ranges,as.data.frame(matrix(0, ncol=100, nrow=0, dimnames=list(NULL,paste0(1:100)))))
# setnames(percentile_ranges,"-102","species",skip_absent=TRUE)
# setnames(percentile_ranges,"-101","bioclim",skip_absent=TRUE)
# 
# number_of_trees <- length(tree_names)
# number_of_vars <- length(bioclim_vars)
# 
# 
# 
# for (i in 1:number_of_trees) {
#   for (j in 1:number_of_vars) {
#     # Select single species and bioclimatic variable from all the data
#     bioclim_var <- bioclim_vars[j]
#     print(bioclim_var)
#     tree <- tree_names[i]
#     print(tree)
#     data <- na.omit(trees[master_list_name==tree_names[i], ..bioclim_var])
#     colnames(data) <- "bioclim"
#     
#     # Calculate absolute distance to mean
#     data[,mean_distance:=abs(bioclim-mean(bioclim, na.rm = TRUE))]
#     setorder(data, cols = "mean_distance")
#     number_of_observations <- nrow(data)/100
#     # Build data.table to be filled with percentiles
#     # In the format of: 
#     # columns: "master_list_name", "bioclim", "bound",percentile 1-100
#     #percentile_ranges <- as.data.frame(matrix(0, ncol=104, nrow=0, dimnames=list(NULL,paste0(-1:100))))
#     row_number <- ((i-1)*number_of_vars)+j
#     print(row_number)
#     
#     percentile_ranges[row_number,1]=tree
#     percentile_ranges[row_number,2]=bioclim_var
#     
#     # Fill with percentiles
#     for (k in c(1:100)) {
#       
#       percentile=round(number_of_observations*k) # 100. quintile encompasses 100% of observation it is thus 0% good for growth
#       percentile_ranges[row_number,(103-k)] <- min(data[1:percentile,bioclim]) 
#       percentile_ranges[row_number,(102+k)] <- max(data[1:percentile,bioclim])
#       
#     }
#     
#     
#     
#   }
# }
# 
# 
# # Write this into the data base:
# fwrite(percentile_ranges,"2_Data/1_Output/all_percentile_ranges_extra_wide.csv")

# 
# # Load libraries
# if(!require(librarian)) install.packages("librarian")
# library(librarian)
# shelf(data.table,stringr, sf,ggplot2,moments)
# 
# # Load data, extract list of tree names
# trees <- fread("~/Downloads/tree_db.csv")
# tree_names <- unique(trees[,master_list_name,])
# tree_names
# bioclim_vars <- colnames(trees)
# bioclim_vars <- bioclim_vars[3:length(bioclim_vars)]
# 
# 
# # Create data.table for results
# all_percentile_ranges  <- data.table(matrix(nrow = 0, ncol = 6)) 
# colnames(all_percentile_ranges) <- c("master_list_name","bioclim","lower_percentile","upper_percentile","lower_range","upper_range")
# # Run loop
# for (i in 1:length(tree_names)) {
#   for (j in 1:length(bioclim_vars)) {
#     # Select single species and bioclimatic variable from all the data
#     bioclim_var <- bioclim_vars[j]
#     print(bioclim_var)
#     tree <- tree_names[i]
#     print(tree)
#     data <- na.omit(trees[master_list_name==tree_names[i], ..bioclim_var])
#     colnames(data) <- "bioclim" # macht nicht was ich will also unelegant
#     
#     # Calculate absolute distance to mean
#     data[,mean_distance:=abs(bioclim-mean(bioclim, na.rm = TRUE))]
#     setorder(data, cols = "mean_distance")
#     # Build data.table to be filled with percentiles
#     # In the format of: 
#     # columns:"master_list_name", "bioclim", "lower_percentile", "upper_percentile", "lower_range", "upper_range"
#     # rows: percentile 1-100
#     percentile_ranges <- data.table(master_list_name=tree,bioclim=bioclim_var,lower_percentile=1:100,upper_percentile=1:100,lower_range=0,upper_range=0)
#     # Fill with percentiles
#     for (k in c(1:100)) {
#       percentile=round(nrow(data)/100*k)
#       percentile_ranges[lower_percentile==(101-k)&master_list_name==tree&bioclim==bioclim_var,lower_range:=min(data[1:percentile,bioclim])]
#       percentile_ranges[upper_percentile==(101-k)&master_list_name==tree&bioclim==bioclim_var,upper_range:=max(data[1:percentile,bioclim])]
#       percentile_ranges
#     }
#     
#     all_percentile_ranges <- rbind(all_percentile_ranges,percentile_ranges)
#     
#   }
# }
# 
# fwrite(all_percentile_ranges,"2_Data/1_Output/all_percentile_ranges_long.csv")
# 
# ###################################################################################################
# 
# # Load libraries
# if(!require(librarian)) install.packages("librarian")
# library(librarian)
# shelf(data.table,stringr, sf,ggplot2,moments)
# 
# # Load data, extract list of tree names
# trees <- fread("~/Downloads/tree_db.csv")
# tree_names <- unique(trees[,master_list_name,])
# tree_names
# bioclim_vars <- colnames(trees)
# bioclim_vars <- bioclim_vars[3:length(bioclim_vars)]
# 
# 
# percentile_ranges <- as.data.frame(matrix(0, ncol=103, nrow=0, dimnames=list(NULL,paste0(-2:100))))
# 
# setnames(percentile_ranges,"-2","species",skip_absent=TRUE)
# setnames(percentile_ranges,"-1","bioclim",skip_absent=TRUE)
# setnames(percentile_ranges,"0","bound",skip_absent=TRUE)
# 
# number_of_trees <- length(tree_names)
# number_of_vars <- length(bioclim_vars)
# 
# 
# 
# for (i in 1:number_of_trees) {
#   for (j in 1:number_of_vars) {
#     # Select single species and bioclimatic variable from all the data
#     bioclim_var <- bioclim_vars[j]
#     print(bioclim_var)
#     tree <- tree_names[i]
#     print(tree)
#     data <- na.omit(trees[master_list_name==tree_names[i], ..bioclim_var])
#     colnames(data) <- "bioclim" # macht nicht was ich will also unelegant
#     
#     # Calculate absolute distance to mean
#     data[,mean_distance:=abs(bioclim-mean(bioclim, na.rm = TRUE))]
#     setorder(data, cols = "mean_distance")
#     number_of_observations <- nrow(data)/100
#     # Build data.table to be filled with percentiles
#     # In the format of: 
#     # columns: "master_list_name", "bioclim", "bound",percentile 1-100
#     #percentile_ranges <- as.data.frame(matrix(0, ncol=104, nrow=0, dimnames=list(NULL,paste0(-1:100))))
#     row_number <- ((i-1)*number_of_vars)*2+j*2-1
#     print(row_number)
#     
#     percentile_ranges[row_number,1]=tree
#     percentile_ranges[row_number,2]=bioclim_var
#     percentile_ranges[row_number,3]="lower"
#     percentile_ranges[row_number+1,1]=tree
#     percentile_ranges[row_number+1,2]=bioclim_var
#     percentile_ranges[row_number+1,3]="upper"
#     
#     # Fill with percentiles
#     for (k in c(1:100)) {
#       
#       percentile=round(number_of_observations*k)
#       percentile_ranges[row_number,103-k] <- min(data[1:percentile,bioclim])
#       percentile_ranges[row_number+1,103-k] <- max(data[1:percentile,bioclim])
#       
#     }
#     
#     
#     
#   }
# }
# 
# fwrite(percentile_ranges,"2_Data/1_Output/all_percentile_ranges_wide.csv")
# 
# 



