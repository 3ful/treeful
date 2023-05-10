# download automatically what is possible to download. 


#################### Trees4F from figshare ###################
if (!file.exists("2_Data/0_raw_data/EUforestspecies_AMauri.csv")) {
  download.file("https://springernature.figshare.com/ndownloader/files/6662535", destfile = "2_Data/0_raw_data/EUforestspecies_AMauri.csv")
}

#####################  CHELSA ############################
# get BIO01for 1981 to 2010
if (!file.exists("2_Data/0_raw_data/CHELSA/CHELSA_bio1_1981-2010_V.2.1.tif")) {
  download.file("https://os.zhdk.cloud.switch.ch/envicloud/chelsa/chelsa_V2/GLOBAL/climatologies/1981-2010/bio/CHELSA_bio1_1981-2010_V.2.1.tif", 
                destfile = "2_Data/0_raw_data/CHELSA/CHELSA_bio1_1981-2010_V.2.1.tif")
}
#get BIO12 for 1981 to 2010
if (!file.exists("2_Data/0_raw_data/CHELSA/CHELSA_bio12_1981-2010_V.2.1.tif")) {
  download.file("https://os.zhdk.cloud.switch.ch/envicloud/chelsa/chelsa_V2/GLOBAL/climatologies/1981-2010/bio/CHELSA_bio12_1981-2010_V.2.1.tif", 
                destfile = "2_Data/0_raw_data/CHELSA/CHELSA_bio12_1981-2010_V.2.1.tif")
}
#get BIO01 for SSP370 model GFDL-ESM4 2041 to 2070
if (!file.exists("2_Data/0_raw_data/CHELSA/CHELSA_bio1_2041-2070_gfdl-esm4_ssp370_V.2.1.tif")) {
  download.file("https://os.zhdk.cloud.switch.ch/envicloud/chelsa/chelsa_V2/GLOBAL/climatologies/2041-2070/GFDL-ESM4/ssp370/bio/CHELSA_bio1_2041-2070_gfdl-esm4_ssp370_V.2.1.tif", 
                destfile = "2_Data/0_raw_data/CHELSA/CHELSA_bio1_2041-2070_gfdl-esm4_ssp370_V.2.1.tif")
}
#get BIO12 for SSP370 model GFDL-ESM4 2041 to 2070
if (!file.exists("2_Data/0_raw_data/CHELSA/CHELSA_bio12_2041-2070_gfdl-esm4_ssp370_V.2.1.tif")) {
  download.file("https://os.zhdk.cloud.switch.ch/envicloud/chelsa/chelsa_V2/GLOBAL/climatologies/2041-2070/GFDL-ESM4/ssp370/bio/CHELSA_bio12_2041-2070_gfdl-esm4_ssp370_V.2.1.tif", 
                destfile = "2_Data/0_raw_data/CHELSA/CHELSA_bio12_2041-2070_gfdl-esm4_ssp370_V.2.1.tif")
}


# wordclim
## Their servers are often overloaded. Might need a few tries. 
## CAREFUL this dataset is 10GB large. 
if (!file.exists("2_Data/0_raw_data/wc2.1_30s/wc2.1_30s_bio.zip")) {
  download.file("https://geodata.ucdavis.edu/climate/worldclim/2_1/base/wc2.1_30s_bio.zip", 
                destfile = "2_Data/0_raw_data/wc2.1_30s/wc2.1_30s_bio.zip")
}
## TO DO: write unzip with utils

