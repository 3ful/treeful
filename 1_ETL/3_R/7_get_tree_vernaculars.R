library(librarian)
shelf(rvest)
# load list with botanical names and taxonomy IDs
tree_master_list <- fread("2_Data/1_output/eu_native_trees_master.csv")

# a simple function to search wikipedia for botanical names
wikipedia <- function(search_terms, lang = c("en", "de", "es", "fr")) {
    # if system language contains "en" use English Wikipedia version
    if (grepl("en", lang)) {
      return(paste0("https://en.wikipedia.org/w/index.php?search=", URLencode(search_terms)))
    }
    
    # if system language contains "de" use German Wikipedia version
    else if (grepl("de", lang)) {
      return(paste0("https://de.wikipedia.org/w/index.php?search=", URLencode(search_terms)))
    }
    
    
    # if "lang" is not specified and default system language is not
    # English, German, Spanish or French, use the English version
    else {
      return(paste0("https://en.wikipedia.org/w/index.php?search=", URLencode(search_terms)))
    }
  }

# scrape wikipedia for first paragraph and image
for (i in 1:nrow(tree_master_list)) {
  tree_url <- wikipedia(tree_master_list$latin_name[i], "de")
  tree_page <-  tree_url %>% 
    rvest::read_html()
  
  tree_tribble <- tibble::tribble(~descr_de, ~url, ~image_url,
                  rvest::html_text(rvest::html_element(tree_page, xpath = "/html/body/div[3]/div[3]/div[5]/div[1]/p[1]"), trim = TRUE),
                  tree_url,
                  rvest::html_attr(html_element(tree_page, xpath = "/html/body/div[3]/div[3]/div[5]/div[1]/table[1]/tbody/tr[2]/td/span/a/img"), "src")
                  ) 
  tree_master_list$descr_de[i] <- tree_tribble$descr_de
  tree_master_list$url[i] <- tree_tribble$url
  tree_master_list$image_url[i] <- tree_tribble$image_url
  cat("fetched ", tree_tribble$descr_de, " \n for ", tree_master_list$latin_name[i])
  # be kind to wikipedia
  Sys.sleep(1.2)
}

tree_master_list <- tree_master_list %>% 
  mutate(image_url = stringr::str_remove(image_url, "^\\/\\/"))

sendstatus("writing master list with drescriptions to postgres")

fwrite(tree_master_list, "2_Data/1_output/eu_native_trees_master.csv")
con <- backend_con()
RPostgres::dbWriteTable(con, "tree_master_list", tree_master_list, overwrite = TRUE)

DBI::dbDisconnect(conn = con)


