# This file converts KMZ files (GEE format ) into clean tidy datasets for validation of Mouza census schools data and results
#And prepares a Final Data frame
###############################################################################

library(sf)
library(tidyverse)
library(rvest)
library(httr)


###############################################################################

#KMZ files (Zipped kmls)

district_kmz <- list.files("../data/KP Schools Data", 
                           pattern = "*.kmz", 
                           full.names = FALSE)

district_kmz    # 25 Districts in KP covered

#Unzipping KMZs
kml_folders <- sapply(district_kmz, 
                      function(x) 
                        unzip(zipfile = paste0("../data/KP Schools Data/", x),
                              exdir   = paste0("../data/KP Schools Data/KML/", x))
)

districts_kmz <- paste0(list.files("../data/KP Schools Data/KML", 
                                   pattern = "*.kmz", 
                                   full.names = TRUE),"/doc.kml")


# district <- sapply(districts_kmz,
#                    function(x)
#                      list.files(x,
#                                  pattern = "*.kml",
#                                 full.names = FALSE))

#Reading KML files
dist  <- lapply(districts_kmz, 
                function(x)
                  read_sf(x))

#Converting all KMLs into a dataframe
dist <- map_dfr(dist, bind_rows)
###############################################################################

# torghar <- read_sf("../data/KP Schools Data/KML/Torghar.kmz/doc.kml")

attributes <- lapply(X = 1:nrow(dist), 
                     FUN = function(x) {
                       
                       dist %>% 
                         slice(x) %>%
                         pull(Description) %>%
                         read_html() %>%
                         html_node("table") %>%
                         html_table(header = TRUE, trim = TRUE, dec = ".", fill = TRUE) %>%
                         as.matrix() %>% 
                         as_tibble() %>% 
                         select(1:2) %>%
                         as_tibble(.name_repair = ~ make.names(c("Attribute", "Value"))) %>% 
                         slice_tail(n=-1)%>% 
                         pivot_wider(names_from = Attribute, values_from = Value) 
                     })

###############################################################################
#making a dataframe and cleaning
kp_schools <- 
  map_dfr(attributes, bind_rows) %>% 
  rename(longitude = X, latitude = Y) %>% 
  janitor::clean_names()

###############################################################################

#KP Schools GIS data in CSV Format for Econometric analysis and analytics
kp_schools %>% 
  write_csv("../data/KP_Schools_GeoData.csv")


#Making a table, at tehsil level on the number of schools at diff levels
#To compare with MOuza census

kp_schools %>%
  count(district, tehsil, school_leve, school_gend) %>%
  pivot_wider(names_from = c("school_leve", "school_gend") , values_from = n) %>% 
  rio::export("../data/Number_of_Schools_GIS.xlsx")

# View()


#Abbottabad has 3 functional boys primary school in same village

###############################################################################
#Mouza census cover 9773,
#lot of repitition in villages - spelling mistakes
# Not much repitition in school names

# kp_schools %>% mutate(school_name= str_remove_all(school_name, "GPS"), school_name= str_to_lower(school_name)) %>% arrange(school_name) %>%   distinct(school_name) %>% View()

# kp_schools %>% mutate(village= str_to_lower(village)) %>% arrange(village) %>%   distinct(village) %>% View()

###############################################################################
