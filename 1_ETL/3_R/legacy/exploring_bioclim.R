if(!require(librarian)) install.packages("librarian")
library(librarian)
shelf(data.table,stringr, sf,ggplot2,moments)
trees <- fread("~/Downloads/tree_db.csv")


tree_names <- unique(trees[,master_list_name,])
tree_names

i=25
j=3


# Select single species and bioclimatic variable from all the data
bioclim_var <- colnames(trees)[j]
bioclim_var
tree <- tree_names[i]
tree
data <- na.omit(trees[master_list_name==tree_names[i], ..bioclim_var])
colnames(data) <- "bioclim" # macht nicht was ich will also unelegant

# Calculate absolute distance to mean
data[,mean_distance:=abs(bioclim-mean(bioclim,na.rm = TRUE))]

fsort(data[,mean_distance])

for (percent in c(1:100)) {
  percent
  print(percent)
}
nrow(data)

quantile()
x = data[,bioclim]
quantile(x,  probs = c(0.1, 0.5, 1, 2, 5, 10, 50, NA)/100)
stopifnot(t(quantAll(x, prob=0:1)) == range(x))

# select bioclim variable

####################
# Select single species and bioclimatic variable from all the data
colnames(trees)
tree_names
i=1
j=3

bioclim_var <- colnames(trees)[j]
bioclim_var
tree <- tree_names[i]
tree
data <- na.omit(trees[master_list_name==tree_names[i], ..bioclim_var])
colnames(data) <- "bioclim" 



# -273.15 from kelvin to celsius
summary(data[,bioclim-273.15])
#mean(data)
#range(data)
var(data[,bioclim-273.15])
skewness(data[,bioclim-273.15]) # -1 ist linksschief und rechtssteil, Schiefe liegt zwischen [-1,1]
hist(data[,bioclim-273.15],xlab="Temperature",ylab="Frequency", main=paste("Histogram of ",tree, " for average yearly temperature"))


plot(ecdf(data[,bioclim-273.15])) 
data

data[]

View(as.data.table(tree_names))





