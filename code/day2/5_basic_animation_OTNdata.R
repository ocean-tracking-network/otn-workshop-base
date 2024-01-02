library(glatos)
library(sf)
library(mapview)
library(plotly)
library(gganimate)
library(ggmap)
library(tidyverse)


setwd("/YOUR/PATH/TO/data/otn")

unzip('nsbs_matched_detections_2022.zip', overwrite = TRUE)

detection_events <- #create detections event variable
  read_otn_detections('nsbs_matched_detections_2022.csv') %>%
  false_detections(tf = 3600) %>%  #find false detections
  dplyr::filter(passed_filter != FALSE) %>% 
  detection_events(location_col = 'station', time_sep=3600)

plot_data <- detection_events %>% 
  dplyr::select(animal_id, mean_longitude,mean_latitude, first_detection)

one_fish <- plot_data[plot_data$animal_id == "NSBS-1393342-2021-08-10",] 

basemap <- 
  get_stadiamap(
    bbox = c(left = min(one_fish$mean_longitude),
             bottom = min(one_fish$mean_latitude), 
             right = max(one_fish$mean_longitude), 
             top = max(one_fish$mean_latitude)),
    maptype = "stamen_toner_lite",
    crop = FALSE, 
    zoom = 7)

otn.plot <-
  ggmap(basemap) +
  geom_point(data = one_fish, aes(x = mean_longitude, y = mean_latitude), size = 2) +
  geom_path(data = one_fish, aes(x = mean_longitude, y = mean_latitude)) +
  labs(title = "NSBS animation",
       x = "Longitude", y = "Latitude", color = "Tag ID")

ggplotly(otn.plot)

otn.plot <-
  otn.plot +
  labs(subtitle = 'Date: {format(frame_along, "%d %b %Y")}') +
  transition_reveal(first_detection) +
  shadow_mark(past = TRUE, future = FALSE)

animate(otn.plot)
