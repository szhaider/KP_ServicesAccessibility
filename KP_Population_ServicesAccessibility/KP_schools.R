# This file converts KMZ files (GEE format ) into clean tidy datasets for validation of Mouza census schools data and results

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


dist  <- lapply(districts_kmz, 
                    function(x)
                    read_sf(x)
)

dist <- map_dfr(dist, bind_rows)
###############################################################################

# torghar <- read_sf("../data/KP Schools Data/KML/Torghar.kmz/doc.kml")

# Option a) Using a simple lapply
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

kp_schools <- 
  map_dfr(attributes, bind_rows) %>% 
  rename(longitude = X, latitude = Y) %>% 
  janitor::clean_names()

###############################################################################

#KP Schools GIS data in CSV Format for Econometric analysis and analytics
kp_schools %>% 
  write_csv("../data/KP_Schools_GeoData.csv")

###############################################################################
