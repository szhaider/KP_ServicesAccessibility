
################################################################################
#Logistic Models 
################################################################################

library(broom)

#Model Data
model_data <- kp_schools %>% 
  # filter(school_leve %in% c("Middle")) %>% 
  filter(water != "Unknown",
         electicity != "Unknown") %>% 
  mutate(
    teaching_st = as.numeric(teaching_st),
    latrine_usa = as.numeric(latrine_usa),
    boys= as.numeric(boys), 
    girls=as.numeric(girls),
    # student_teacher_ratio = ((boys+girls)/teaching_st),
    boudary_wal = ifelse(boudary_wal == "Yes", 1, 0),
    electicity =  ifelse(electicity ==  "Yes", 1, 0),
    water = ifelse(water == "Yes", 1, 0),
    geo_locatio = ifelse(geo_locatio == "Rural", 1, 0),
    class_rooms = as.numeric(class_rooms)
    # school_gend = ifelse(school_gend == "Boys", 1, 0)
  ) %>% 
  na.omit()


#Model (Boundary Wall Vs no wall)
logistic_model_bw <-
  glm(boudary_wal  ~ school_gend + water + electicity + geo_locatio+
        # present_sta +    #school_leve +
        teaching_st + latrine_usa ,  #+ student_teacher_ratio + class_rooms
      data=model_data, 
      family="binomial") 


summary(logistic_model_bw)

#Model (Electricty vs no electricty)
logistic_model_el <-
  glm(electicity  ~ school_gend + water  + boudary_wal + geo_locatio +
        teaching_st + latrine_usa,
      data=model_data, 
      family="binomial") 

summary(logistic_model_el)


#Model (Water availability vs unavailability)
logistic_model_wt <-
  glm(water  ~ school_gend + electicity  + boudary_wal + geo_locatio+
        teaching_st + latrine_usa,
      data=model_data, 
      family="binomial") 

summary(logistic_model_wt)


##Number of classrooms - insignificnat in all models

#Boundary Wall coef plot
logistic_model_bw %>% 
  tidy(conf.int=TRUE) %>% 
  select(term, estimate, conf.low, conf.high) %>% 
  filter(term != "(Intercept)") %>% 
  mutate(term =
           case_when(
             term == "school_gendGirls" ~ "Girls School vs. Boys School",
             term == "water" ~ "Water Available vs, Unavailable",
             term == "electicity" ~ "Electricity Available vs. Unavailable",
             term == "teaching_st" ~ "Teaching Staff (Number)",
             # # term == "school_leveHigher Secondary" ~ "Higher Secondary",
             # term == "school_leveMiddle" ~ "Middle School",
             # term == "school_levePrimary" ~ "Primary School",
             # term == "present_staTemp.Closed" ~ "Presently Closed",
             # term == "class_rooms" ~ "Class Rooms (Number)",
             term =="geo_locatio" ~ "Rural vs. Urban",
             term == "latrine_usa" ~ "Tiolets (Number)"
             
           )) %>% 
  mutate(term = fct_reorder(term, estimate)) %>% 
  ggplot(aes(term, estimate))+
  geom_point(color="midnightblue")+
  geom_errorbar(aes(ymin= conf.low, ymax=conf.high), width=0.1, color="midnightblue")+
  # geom_col()+
  coord_flip()+
  ggtitle("Logit Model (Boundary Wall vs. No Boundary Wall for Schools)")+
  labs(y= "Log of Odds",
       x= "Terms")


#Electricity model plot
logistic_model_el %>% 
  tidy(conf.int=TRUE) %>% 
  select(term, estimate, conf.low, conf.high) %>% 
  filter(term != "(Intercept)") %>% 
  mutate(term =
           case_when(
             term == "school_gendGirls" ~ "Girls School vs. Boys School",
             term == "water" ~ "Water Available vs, Unavailable",
             term == "boudary_wal" ~ "Boundary Wall vs. No Wall",
             term == "teaching_st" ~ "Teaching Staff (Number)",
             term =="geo_locatio" ~ "Rural vs. Urban",
             term == "latrine_usa" ~ "Tiolets (Number)"
             
           )) %>% 
  mutate(term = fct_reorder(term, estimate)) %>% 
  ggplot(aes(term, estimate))+
  geom_point(color="midnightblue")+
  geom_errorbar(aes(ymin= conf.low, ymax=conf.high), width=0.1, color="midnightblue")+
  coord_flip()+
  ggtitle("Logit Model (Electricity Available vs. Electricity Unavailable for Schools)")+
  labs(y= "Log of Odds",
       x= "Terms")

#Rural Areas worse off in all models
#Girls worse off in electricty, better off in boundary walls


#Water Availability model plot
logistic_model_wt %>% 
  tidy(conf.int=TRUE) %>% 
  select(term, estimate, conf.low, conf.high) %>% 
  filter(term != "(Intercept)") %>% 
  mutate(term =
           case_when(
             term == "school_gendGirls" ~ "Girls School vs. Boys School",
             term == "electicity" ~ "Electricity Available vs. Unavailable",
             term == "boudary_wal" ~ "Boundary Wall vs. No Wall",
             term == "teaching_st" ~ "Teaching Staff (Number)",
             term =="geo_locatio" ~ "Rural vs. Urban",
             term == "latrine_usa" ~ "Tiolets (Number)"
             
           )) %>% 
  mutate(term = fct_reorder(term, estimate)) %>% 
  ggplot(aes(term, estimate))+
  geom_point(color="midnightblue")+
  geom_errorbar(aes(ymin= conf.low, ymax=conf.high), width=0.1, color="midnightblue")+
  coord_flip()+
  ggtitle("Logit Model (Water Available vs. Water Unavailable for Schools)")+
  labs(y= "Log of Odds",
       x= "Terms")

#Girls worse off in water availability - over all KP










