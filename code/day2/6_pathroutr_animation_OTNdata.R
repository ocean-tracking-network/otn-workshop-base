library(glatos)
library(sf)
library(gganimate)
library(tidyverse)
library(pathroutr)
library(ggspatial)
library(sp)
library(raster)
library(geodata)

setwd("YOUR/PATH/TO/data/otn")

detection_events <- #create detections event variable
  read_otn_detections('nsbs_matched_detections_2022/nsbs_matched_detections_2022.csv') %>% # reading detections
  false_detections(tf = 3600) %>%  #find false detections
  dplyr::filter(passed_filter != FALSE) %>% 
  detection_events(location_col = 'station', time_sep=3600)

plot_data <- detection_events %>% 
  dplyr::select(animal_id, mean_longitude,mean_latitude, first_detection)

one_fish <- plot_data[plot_data$animal_id == "NSBS-1393342-2021-08-10",] 

#Shift the detections closer to the land so as to give a more fulsome demonstration of pathroutr's capabilities.
one_fish_shifted <- one_fish %>% mutate(mean_longitude_shifted = mean_longitude-0.5)

CAN<-gadm('CANADA', level=1, path="./geodata", resolution=2)

shape_file <- CAN[CAN$NAME_1 == 'Nova Scotia',]

ns_polygon <- st_as_sf(shape_file)  %>% st_transform(5070)

path <- one_fish_shifted %>%  dplyr::select(mean_longitude_shifted,mean_latitude)

path <- SpatialPoints(path, proj4string = CRS("+proj=longlat +datum=WGS84 +no_defs"))

path <-  st_as_sf(path)  %>% st_transform(5070)

ggplot() + 
  ggspatial::annotation_spatial(ns_polygon, fill = "cornsilk3", size = 2) +
  geom_point(data = path, aes(x=unlist(map(geometry,1)), y=unlist(map(geometry,2)))) +
  geom_path(data = path, aes(x=unlist(map(geometry,1)), y=unlist(map(geometry,2))))  +
  theme_void()

plot_path <- path %>% st_cast('MULTIPOINT') %>% summarise(do_union = FALSE) %>% st_cast('LINESTRING')

track_pts <- st_sample(plot_path, size = 10000, type = "regular")

#This takes a WHILE to run. 
vis_graph <- prt_visgraph(ns_polygon, buffer = 100)

#This too.
track_pts_fix <- prt_reroute(track_pts, ns_polygon, vis_graph, blend = TRUE)

track_pts_fix <- prt_update_points(track_pts_fix, track_pts)

pathroutrplot <- ggplot() + 
  ggspatial::annotation_spatial(ns_polygon, fill = "cornsilk3", size = 0) +
  geom_point(data = track_pts_fix, aes(x=unlist(map(geometry,1)), y=unlist(map(geometry,2)))) +
  geom_path(data = track_pts_fix, aes(x=unlist(map(geometry,1)), y=unlist(map(geometry,2))))  +
  theme_void()

pathroutrplot

pathroutrplot.animation <-
  pathroutrplot +
  transition_reveal(fid) +
  shadow_mark(past = T, future = F)

gganimate::animate(pathroutrplot.animation, nframes=100, detail=2)
