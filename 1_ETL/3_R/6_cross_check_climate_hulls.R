############ Load Packages ############ 
if(!require(librarian)) install.packages("librarian")
library(librarian)
shelf(data.table,stringr, sf, tidyverse, raster, hrbrthemes, paletteer, hexbin, RSQLite, DBI)




################### get full tree DB with bioclim vars from sqlite ###################
#if (!exists("tree_dbs")) {tree_dbs <- fread("2_Data/1_output/tree_db.csv")}

# somehow sqlite stuff not wokring. its writing something into the DB but then no tables when querying
# con <-RSQLite::dbConnect(RSQLite::SQLite("2_Data/1_output/tree_db.sqlite"))
# tree_dbs <- dbReadTable(con, "tree_occurrence")

tree_dbs <- data.table::fread(file = "2_Data/1_output/tree_db.csv")
tree_dbs <- left_join(tree_dbs, dplyr::select(tree_master_list, name, name_de), by = c("master_list_name" = "name"))

hull_plot <- tree_dbs %>% 
  filter(!is.na(name_de)) %>% 
  #filter(db == "cadastres") %>% 
  ggplot() +
  #geom_hex(aes(x = prec, y = temp), bins = 70) +
  #geom_bin2d(aes(x = prec, y = temp), bins = 20) +
  #scale_fill_continuous(type = "viridis") +
  geom_point(aes(x = bio12_copernicus_1979_2018, y = bio01_copernicus_1979_2018, color = db), alpha = 0.1, lwd = 0) +
  #geom_point(data = st_drop_geometry(gbif_sf), aes(x = prec, y = temp), color = "pink", lwd = 0, alpha = 0.3) +
  #geom_point(data = user_climate1, aes(x = bio12_hist, y = bio01_hist), color = "darkslategray") +
  #geom_point(data = user_climate1, aes(x = bio12_future, y = bio01_future), color = "darkslategray4") +
  geom_point(data = user_climate1, aes(x = bio12_hist, y = bio01_hist), color = "darkolivegreen4") +
  geom_point(data = user_climate1, aes(x = bio12_future, y = bio01_future), color = "darkolivegreen") +
  #geom_point(aes(x = prec_now, y = tmp_now), color = "blue") +
  scale_color_paletteer_d("wesanderson::Royal1") +
  facet_wrap(~name_de, scales = "free") +
  theme_ipsum() +
  labs(title = "Jahrestemperatur und Jahresniederschlag: Habitate aus 6 Millionen Baumstandorten", 
       subtitle = "Fixpunkte: Oberbösa Durchschnittskima 1979-2018 und 2030-2050") +
  theme(plot.background = element_rect(fill = "black"), 
        text = element_text(color = "white"), 
        strip.text = element_text(color = "white")) 
ggsave(hull_plot, filename = "figs/temp_prec_OB.png", width = 40, height= 40)



######################### Comparing the source rasters #######################


bio01 <- getpastclimate(source = "copernicus", bioclim = "bio01")
bio12 <- getpastclimate(source = "copernicus", bioclim = "bio12")
future_raster <- getfutureclimate(source = "copernicus")
source("3_R/5_fn_user_location.R")
user_climate_copernicus <- get_user_climate()

bio01 <- getpastclimate(source = "chelsa", bioclim = "bio01")
bio12 <- getpastclimate(source = "chelsa", bioclim = "bio12")
future_raster <- getfutureclimate(source = "chelsa")
source("3_R/5_fn_user_location.R")
user_climate_chelsa <- get_user_climate()

bio01 <- getpastclimate(source = "worldclim", bioclim = "bio01")
bio12 <- getpastclimate(source = "worldclim", bioclim = "bio12")
future_raster <- getfutureclimate(source = "worldclim")
source("3_R/5_fn_user_location.R")
user_climate_worldclim <- get_user_climate()


for (i in 1:nrow(common_trees)) {
  
  species <- filter(tree_dbs, master_list_name == common_trees$master_list_name[i])
  
  copernicus <- ggplot(data = species) +
    geom_point(aes(x = bio12_copernicus_1979_2018, y = bio01_copernicus_1979_2018, color = db), alpha = 0.2, lwd = 0) +
    geom_point(data = user_climate_copernicus, aes(x = bio12_hist, y = bio01_hist), color = "grey40") +
    geom_point(data = user_climate_copernicus, aes(x = bio12_future, y = bio01_future), color = "orange") +
    #geom_point(aes(x = prec_now, y = tmp_now), color = "blue") +
    scale_color_paletteer_d("wesanderson::Royal1") +
    theme_ipsum() +
    labs(subtitle = "Copernicus Past: 1979-2018, Copernicus Future: 2030-2050", 
         title = common_trees$master_list_name[i]) +
    theme(plot.background = element_rect(fill = "black"), 
          text = element_text(color = "white"), 
          strip.text = element_text(color = "white")) 
  
  chelsa <- ggplot(data = species) +
    geom_point(aes(x = bio12_chelsa_1981_2010, y = bio01_chelsa_1981_2010, color = db), alpha = 0.2, lwd = 0) +
    geom_point(data = user_climate_chelsa, aes(x = bio12_hist, y = bio01_hist), color = "grey40") +
    geom_point(data = user_climate_chelsa, aes(x = bio12_future, y = bio01_future), color = "orange") +
    #geom_point(aes(x = prec_now, y = tmp_now), color = "blue") +
    scale_color_paletteer_d("wesanderson::Royal1") +
    theme_ipsum() +
    labs(subtitle = "Chelsa Past: 1981-2010, Chelsa Future: 2041-2070", 
         title = common_trees$master_list_name[i]) +
    theme(plot.background = element_rect(fill = "black"), 
          text = element_text(color = "white"), 
          strip.text = element_text(color = "white")) 
  
  
  worldclim <- ggplot(data = species) +
    geom_point(aes(x = bio12_worldclim_1970_2000, y = bio01_worldclim_1970_2000, color = db), alpha = 0.2, lwd = 0) +
    geom_point(data = user_climate_worldclim, aes(x = bio12_hist, y = bio01_hist), color = "grey40") +
    geom_point(data = user_climate_worldclim, aes(x = bio12_future, y = bio01_future), color = "orange") +
    scale_color_paletteer_d("wesanderson::Royal1") +
    theme_ipsum() +
    labs(subtitle = "Worldclim Past: 1970-2000, Worldclim: 2041-2060", 
         title = common_trees$master_list_name[i]) +
    theme(plot.background = element_rect(fill = "black"), 
          text = element_text(color = "white"), 
          strip.text = element_text(color = "white")) 
  
  species_plot <- ggpubr::ggarrange(copernicus, chelsa, worldclim, nrow = 1, common.legend = TRUE)
  ggsave(species_plot, filename = paste0("figs/compare_rasters/", i, ".png"), width = 16, height = 8)
  print(i)
}



