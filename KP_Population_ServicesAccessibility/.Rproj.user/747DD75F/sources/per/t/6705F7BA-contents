library(raster)
library(sf)
library(janitor)
library(dplyr)

# pak_shp <-
#   read_sf("../PAK_SHP_2022/pak_adm_wfp_20220909_shp/pak_admbnda_adm3_wfp_20220909.shp") %>%
#   st_as_sf() %>%
#   clean_names() %>%
#   as_tibble() %>%
#   filter(adm1_en == "Khyber Pakhtunkhwa")
# 

pak_shp <- 
  shapefile("../PAK_SHP_2022/pak_adm_wfp_20220909_shp/pak_admbnda_adm3_wfp_20220909.shp")

 pak_shp$area_sqkm <- raster::area(pak_shp) /1e6    #Orig in sq/m
 # pak_shp <- terra::expanse(pak_shp, unit= "km,", transform= TRUE)

crs(pak_shp)

pak_shp %>% 
  st_as_sf() %>% 
  as_tibble() %>% 
  select(Shape_Leng,
         Shape_Area,	
         ADM3_EN,
         ADM3_PCODE,
         ADM2_EN,
         ADM2_PCODE,
         ADM1_EN,
         ADM1_PCODE,
         ADM0_EN,
         ADM0_PCODE,
         area_sqkm) %>% 
  filter(ADM1_EN == "Khyber Pakhtunkhwa") %>% 
  write.csv("tehsil_area.csv")


