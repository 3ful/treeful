library(librarian)
shelf(rvest)

tree_master_list <- fread("2_Data/1_output/try_eu_native_trees_master.csv") 

wikipedia <- function(search_terms, lang = c("en", "de", "es", "fr")) {
  if (missing(search_terms)) {
    message("Opening Wikipedia in browser")
    return(paste0("https://www.wikipedia.org"))
  }
  else {
    if (missing(lang)) {
      lang <- Sys.getenv("LANG")
    }
    
    # if system language contains "en" use English Wikipedia version
    if (grepl("en", lang)) {
      return(paste0("https://en.wikipedia.org/w/index.php?search=", URLencode(search_terms)))
    }
    
    # if system language contains "de" use German Wikipedia version
    else if (grepl("de", lang)) {
      return(paste0("https://de.wikipedia.org/w/index.php?search=", URLencode(search_terms)))
    }
    
    # if system language contains "es" use Spanish Wikipedia version
    else if (grepl("es", lang)) {
      return(paste0("https://es.wikipedia.org/w/index.php?search=", URLencode(search_terms)))
    }
    
    # if system language contains "fr" use French Wikipedia version
    else if (grepl("fr", lang)) {
      return(paste0("https://fr.wikipedia.org/w/index.php?search=", URLencode(search_terms)))
    }
    
    # if "lang" is not specified and default system language is not
    # English, German, Spanish or French, use the English version
    else {
      return(paste0("https://en.wikipedia.org/w/index.php?search=", URLencode(search_terms)))
    }
  }
}

wikipedia("taxus baccata", "de") %>% 
  rvest::read_html() %>% 
  rvest::html_element(xpath = "/html/body/div[3]/div[3]/div[5]/div[1]/p[1]") %>% 
  rvest::html_text(trim = TRUE)


tree_master_list <- tree_master_list %>% 
  add_column(tree_descr = "empty")

for (i in 1:nrow(tree_master_list)) {
  tree_text <- wikipedia(tree_master_list$name[i], "de") %>% 
    rvest::read_html() %>% 
    rvest::html_element(xpath = "/html/body/div[3]/div[3]/div[5]/div[1]/p[1]") %>% 
    rvest::html_text(trim = TRUE)
  
  tree_master_list$tree_descr[i] <- tree_text
  cat("fetched ", tree_text, " \\n for ", tree_master_list$name[i])
  Sys.sleep(1.2)
}


