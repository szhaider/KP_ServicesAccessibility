
# Accessibility disparities based on distance from facilities
library(ggplot2)

library(tidyverse)
library(haven)
library(sf)

theme_set(theme_classic())

##################################################
#KP Shape file for Maps

kp_shp <-
  read_sf("../PAK_SHP_2022/pak_adm_wfp_20220909_shp/pak_admbnda_adm3_wfp_20220909.shp") %>% 
  st_as_sf() %>% 
  filter(ADM1_EN =="Khyber Pakhtunkhwa")


##################################################


#Mouza File
mouza <- read_dta("../output/MouzaCensus_Cleaned.dta")

#Mouza to shp mapping
tehsil_shp <- read_dta("../output/tehsil_mouzatoshp2022.dta")

population <- read_dta("../output/population_number.dta") %>% 
  select(-Y)


##################################################

# 
# 
# mouza_services_sums <- read_dta("../output/tehsillevel_services_sums.dta")
# 
# mouza_services_sums <-
#   population %>% 
#   left_join(tehsil_shp,
#             by=c("ADM3_NAME")) %>% 
#   left_join(mouza_services_sums,
#             by=c("tehsil")) %>% 
#   arrange(ADM3_NAME) %>% 
#   distinct( ADM3_NAME, .keep_all=TRUE) %>% 
#   mutate(# Ratios of total services (as in muzas with services within tehsils) services with population 2019-20-WSF
#     primary_pop_ratio = WSF19POP17/ pri_schl_tot,
#     middle_pop_ratio = WSF19POP17/mid_schl_tot ,
#     sec_pop_ratio = WSF19POP17/sec_schl_tot ,
#     hosp_pop_ratio = WSF19POP17/health_facilities,
#     mkt_pop_ratio = WSF19POP17/p6q1311_admin_fac
#   )


# mouza_services_sums %>% count(ADM3_NAME, sort=T)

##################################################
#Merging mouza census with other files
mouza <- mouza %>% 
  left_join(tehsil_shp , 
            by = c("tehsil")) %>% 
  left_join(population,
            by = c("ADM3_NAME")) %>% 
  mutate(
              p3q0871 = ifelse(p3q0871 == 2, p3q0871==0, p3q0871)) %>% 
  mutate(NMDs = 
           as.factor(       
             case_when(
               ADM2_NAME == "Bajaur" ~ "NMDs",
               ADM2_NAME == "Khyber" ~ "NMDs",
               ADM2_NAME == "Kurram" ~ "NMDs",
               ADM2_NAME == "Mohmand" ~ "NMDs",
               ADM2_NAME == "North Waziristan" ~ "NMDs",
               ADM2_NAME == "Orakzai" ~ "NMDs",
               ADM2_NAME == "South Waziristan" ~ "NMDs",
               TRUE ~ "Other KP Tehsils"
             )))


##################################################
# Distance of mouzas from schools - in Kilometers (if mouza doesn;t have school)
#Middle Schools accessibility disparity
mouza %>% 
  select(ADM3_NAME, ADM2_NAME, p4q1121 ,p4q1122, p4q1221, p4q1222,
         p1q10, NMDs) %>%   #Boys + Girls Middle Schools (availability + Distance)
  group_by(ADM3_NAME, NMDs) %>% 
  summarise(p4q1122 = mean(p4q1122, na.rm=T),
            p4q1222 = mean(p4q1222, na.rm=T),
            p1q10 = mean(p1q10)) %>% 
  ungroup() %>% 
  ggplot()+
  geom_abline(intercept = 0, slope = 1)+
  geom_point(aes(p4q1122, p4q1222,
                 color=NMDs,  size=p1q10), alpha=0.5) +
  # geom_smooth(aes(p4q1122, p4q1222), method = lm) +
   coord_cartesian(xlim= c(0, 50), ylim=c(0,50)) +
  labs(size="Average settlements in mouzas",
       x= "Average Distance (Km) from Boys' Middle School",
       y = "Average Distance (Km) from Girls' Middle School")+
  scale_color_manual(values=c("darkred", "midnightblue"))
 
  
#Primary Distirct level
mouza %>% 
  select(ADM3_NAME, ADM2_NAME, p4q1111, p4q1112, p4q1211, p4q1212,
         p1q10, NMDs) %>%   #Boys + Girls Middle Schools (availability + Distance)
  mutate(p4q1112 = as.double(p4q1112)) %>% 
  group_by(ADM3_NAME, NMDs) %>% 
  summarise(p4q1112 = mean(p4q1112, na.rm=T),
            p4q1212 = mean(p4q1212, na.rm=T),
            p1q10 = mean(p1q10)) %>% 
  ungroup() %>% 
  ggplot()+
  geom_abline(intercept = 0, slope = 1)+
  # geom_abline(intercept = 0, slope = 2)+
  
  geom_point(aes(p4q1112, p4q1212,
                 color=NMDs,  size=p1q10), alpha=0.5) +
  # geom_smooth(aes(p4q1112, p4q1212), method = lm) +
  coord_cartesian(xlim= c(0, 25), ylim=c(0,25)) +
  labs(size="Average settlements in mouzas",
       x= "Average Distance (Km) from Boys' Primary School",
       y = "Average Distance (Km) from Girls' Primary School")+
  scale_color_manual(values=c("darkred", "midnightblue"))
  

# Primary Mouza level
mouza %>% 
  select(ADM3_NAME, ADM2_NAME, p4q1111, p4q1112, p4q1211, p4q1212,
         p1q10, NMDs) %>%   #Boys + Girls Middle Schools (availability + Distance)
  mutate(p4q1112 = as.double(p4q1112)) %>% 
  ggplot()+
  geom_abline(intercept = 0, slope = 1)+
  geom_point(aes(p4q1112, p4q1212,
                 color=NMDs,  size=p1q10), alpha=0.1) +
  coord_cartesian(xlim= c(0, 30), ylim=c(0,30)) +
  labs(size="Settlements in mouzas",
       x= "Distance (Km) from Boys' Primary School",
       y = "Distance (Km) from Girls' Primary School")+
  scale_color_manual(values=c("darkred", "midnightblue"))

# Middle School Mouza
mouza %>% 
  select(ADM3_NAME, ADM2_NAME, p4q1121 ,p4q1122, p4q1221, p4q1222,
         p1q10, NMDs) %>%   #Boys + Girls Middle Schools (availability + Distance)
  ggplot()+
  geom_abline(intercept = 0, slope = 1)+
  geom_point(aes(p4q1122, p4q1222,
                 color=NMDs,  size=p1q10), alpha=0.1) +
  coord_cartesian(xlim= c(0, 60), ylim=c(0,60)) +
  labs(size="Settlements in mouzas",
       x= "Distance (Km) from Boys' Middle School",
       y = "Distance (Km) from Girls' Middle School")+
  scale_color_manual(values=c("darkred", "midnightblue"))



