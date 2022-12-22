#Graphs on KP Schools GIS data

library(ggthemes)
theme_set(theme_minimal())

################################################################################

#Gender dimension - student teacher ratio

kp_schools %>% 
  mutate(
    geo_locatio=ifelse(geo_locatio=="Urbon", "Urban", geo_locatio),
    boys = as.numeric(boys),
    girls = as.numeric(girls),
    teaching_st=as.numeric(teaching_st)) %>% 
  filter(
    present_sta=="Functional",
    # school_leve %in% c("Primary"),
    # school_gend %in% c("Boys")
  ) %>%
  mutate(student_teacher_boys = ((boys+girls)/teaching_st)) %>% 
  # View()
  ggplot(aes(student_teacher_boys, fill=school_gend)) +
  geom_histogram(bins = 50, binwidth = 5, alpha=0.5) +
  facet_wrap(~school_leve, nrow=2, scales  ="free_y")+
  labs(x="Student to Teaching Staff ratio",
       y="No. of Schools")+
  labs(fill=c("Boys/Girls"))+
  ggtitle("Students to Teaching Staff ratio - for Functional Schools in KP")

# ggsave("../figures/GIS_KPSchools/St_tea_ratio-gender.png")

###Boys
kp_schools %>% 
  mutate(
    geo_locatio=ifelse(geo_locatio=="Urbon", "Urban", geo_locatio),
    boys = as.numeric(boys),
    girls = as.numeric(girls),
    teaching_st=as.numeric(teaching_st)) %>% 
  filter(
    present_sta=="Functional",
    # school_leve %in% c("Primary"),
    school_gend %in% c("Boys")
  ) %>%
  mutate(student_teacher_boys = ((boys+girls)/teaching_st)) %>% 
  # View()
  ggplot(aes(student_teacher_boys, fill=geo_locatio)) +
  geom_histogram(bins = 50, binwidth = 5, alpha=0.5) +
  facet_wrap(~school_leve, nrow=2, scales  ="free_y")+
  labs(x="Student to Teaching Staff ratio (Boys)",
       y="No. of Schools")+
  labs(fill=c("Rural/Urban"))+
  ggtitle("Students to Teaching Staff ratio (Boys) - for Functional Schools in KP")

###Girls
kp_schools %>% 
  mutate(
    geo_locatio=ifelse(geo_locatio=="Urbon", "Urban", geo_locatio),
    boys = as.numeric(boys),
    girls = as.numeric(girls),
    teaching_st=as.numeric(teaching_st)) %>% 
  filter(
    present_sta=="Functional",
    # school_leve %in% c("Primary"),
    school_gend %in% c("Girls")
  ) %>%
  mutate(student_teacher_boys = ((boys+girls)/teaching_st)) %>% 
  # View()
  ggplot(aes(student_teacher_boys, fill=geo_locatio)) +
  geom_histogram(bins = 50, binwidth = 5, alpha=0.5) +
  facet_wrap(~school_leve, nrow=2, scales  ="free_y")+
  labs(x="Student to Teaching Staff ratio (Girls)",
       y="No. of Schools")+
  labs(fill=c("Rural/Urban"))+
  ggtitle("Students to Teaching Staff ratio (Girls) - for Functional Schools in KP")

################################################################################
#water availability
kp_schools %>% 
  group_by(school_gend) %>% 
  count(school_gend, water) %>% 
  mutate(prop = n/sum(n))
#34% of the Boys schools have no acces to water,25% for girls scools

#Electricity
kp_schools %>% 
  # filter(school_leve=="High") %>% 
  group_by(school_gend) %>% 
  count(school_gend, electicity) %>% 
  mutate(prop = n/sum(n))
# 43.6% of the boys schools have no electricty, 35.4% for girls schools

#Boundary wall
kp_schools %>% 
  group_by(school_gend) %>% 
  count(boudary_wal,school_gend) %>% 
  mutate(prop = n/sum(n)) %>% 
  filter(boudary_wal != "Unknown") %>% 
  ggplot(aes(x=school_gend, y=prop, fill=boudary_wal))+
  geom_col()+
  scale_y_continuous(labels=scales::percent)+
  labs(y="Percent of schools",
       fill="Boundary Wall?")
#Worse for boys


#Laterine Availability
kp_schools %>% 
  filter(latrine_usa==0) %>% 
  group_by(school_gend) %>% 
  count(school_gend, latrine_usa) %>% 
  mutate(prop = n/sum(n))

###############################################################################

# pak_shp <- 
#   rgdal::readOGR("../PAK_SHP_2022/pak_adm_wfp_20220909_shp/pak_admbnda_adm1_wfp_20220909.shp") 
# 
# proj4string(pak_shp)
# 
# lat_long <- spTransform(pak_shp, CRS("+proj=longlat +ellps=WGS84 +datum=WGS84"))
#   
# coords <- coordinates(lat_long) %>% 
#   as_tibble()
# 
# ggplot() +
#   geom_polygon(aes(V1, V2), data=coords, group=group)
#     # mutate(longitude = as.numeric(longitude),
#   #        latitude = as.numeric(latitude)) %>% 
#   # ggplot(aes(longitude, latitude))+
#   # geom_point(size=0.1) +


