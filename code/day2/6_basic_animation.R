library(glatos)
library(sf)
library(mapview)
library(plotly)
library(gganimate)
library(ggmap)
library(tidyverse)


setwd("YOUR/PATH/TO/data/act")

detection_events <- #create detections event variable
  read_otn_detections('proj58_matched_detections_2016.csv') %>% # reading detections
  false_detections(tf = 3600) %>%  #find false detections
  filter(passed_filter != FALSE) %>% 
  detection_events(location_col = 'station', time_sep=3600)

plot_data <- detection_events %>% 
  dplyr::select(animal_id, mean_longitude,mean_latitude, first_detection)

one_fish <- plot_data[plot_data$animal_id == "PROJ58-1218508-2015-10-13",] 

basemap <- 
  get_stamenmap(
    bbox = c(left = min(one_fish$mean_longitude),
             bottom = min(one_fish$mean_latitude), 
             right = max(one_fish$mean_longitude), 
             top = max(one_fish$mean_latitude)),
    maptype = "toner-lite",
    crop = FALSE, 
    zoom = 8)

act.plot <-
  ggmap(basemap) +
  geom_point(data = one_fish, aes(x = mean_longitude, y = mean_latitude), size = 2) +
  geom_path(data = one_fish, aes(x = mean_longitude, y = mean_latitude)) +
  labs(title = "ACT animation",
       x = "Longitude", y = "Latitude", color = "Tag ID")

ggplotly(act.plot)

act.plot <-
  act.plot +
  labs(subtitle = 'Date: {format(frame_along, "%d %b %Y")}') +
  transition_reveal(first_detection) +
  shadow_mark(past = TRUE, future = FALSE)

animate(act.plot)
