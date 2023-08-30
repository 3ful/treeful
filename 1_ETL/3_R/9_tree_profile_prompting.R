if(!require(librarian)) install.packages("librarian")
library(librarian)
shelf(data.table,httr,jsonlite,stringr)


chatGPT <- function(prompt, 
                    modelName = "gpt-3.5-turbo",
                    temperature = 1,
                    apiKey = Sys.getenv("chatGPT_API_KEY")) {
  
  if(nchar(apiKey)<1) {
    apiKey <- readline("Paste your API key here: ")
    Sys.setenv(chatGPT_API_KEY = apiKey)
  }
  
  response <- POST(
    url = "https://api.openai.com/v1/chat/completions", 
    add_headers(Authorization = paste("Bearer", apiKey)),
    content_type_json(),
    encode = "json",
    body = list(
      model = modelName,
      temperature = temperature,
      messages = list(list(
        role = "user", 
        content = prompt
      ))
    )
  )
  
  if(status_code(response)>200) {
    stop(content(response))
  }
  
  trimws(content(response)$choices[[1]]$message$content)
}




# Load data, extract list of tree names
trees <- fread("2_Data/1_output/tree_db.csv") %>% dplyr::select(-geometry)
tree_names <- unique(trees[,master_list_name,])
tree_names <- as.data.table(tree_names)
fwrite(tree_names,"2_Data/1_output/tree_names.csv")



# Create prompt parts
prompt1 <- "Write a profile about "
prompt2 <- ". It must include these points:
1. General information and occurrences
2. Allergies
3. Poisenous
4. Domestic to Europe
5. Grwoth conditions including
	5.1 Soil conditions
	5.2	Nutrients
	5.3 Sunlight
	5.4 Temperatures
	5.5 Moisture
The response should be in German and it should be in the markdown format. Besides the markdown file there should be no other text in the response. The title heading should be the German name and the latein name in brackets afterwards."


chatGPT_API_KEY <- "your_key"

trees <- fread("2_Data/1_Output/tree_names.csv")
trees <- trees[,.(tree_names=paste(V1,tree_names))]

# For manual entering
# tree <- trees[,tree_names][1]
# trees <- trees[107:nrow(trees),]

for (tree in trees[,tree_names]){
prompt <- paste(prompt1,tree,prompt2,sep="")
answer <- chatGPT(prompt=prompt, modelName = "gpt-3.5-turbo", temperature = 0.5)

# Specify the file path and name for the Markdown file
file_path <- paste("2_Data/1_Output/tree_profiles/",
                   str_replace_all(tree, " ", "_"),
                   ".md",
                   sep="")
# Open the file in write mode and write the Markdown content
writeLines(answer, file_path)
# Print a message to confirm the file has been saved
print(cat("Markdown content has been saved to", file_path))
}

trees <- fread("2_Data/1_Output/tree_names.csv")
trees <- trees[,.(tree_names=paste(V1,tree_names))]
trees[,file_names:=paste(str_replace_all(tree_names, " ", "_"),
      ".md",
      sep="")]
existing_files <- as.data.table(list.files(path = "2_Data/1_Output/tree_profiles/", pattern = "*.md"))
colnames(existing_files) <- "file_names"
missing <- data.table(tree_names=trees[!(file_names %in% existing_files[,file_names]),tree_names])
trees <- missing



