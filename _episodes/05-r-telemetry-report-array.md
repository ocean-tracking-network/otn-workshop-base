---
title: Telemetry Reports for Array Operators
teaching: 30
exercises: 0
questions:
    - "How do I summarize and plot my deployments?"
    - "How do I summarize and plot my detections?"
---

### Mapping GLATOS stations - Static map

This section will use the Receivers CSV for the entire GLATOS Network.
~~~
library(ggmap)


#first, what are our columns called?
names(glatos_receivers)


#make a basemap for all of the stations, using the min/max deploy lat and longs as bounding box
#what are our columns called?
names(glatos_receivers)


base <- get_stamenmap(
  bbox = c(left = min(glatos_receivers$deploy_long),
           bottom = min(glatos_receivers$deploy_lat),
           right = max(glatos_receivers$deploy_long),
           top = max(glatos_receivers$deploy_lat)),
  maptype = "terrain-background",
  crop = FALSE,
  zoom = 8)

#filter for stations you want to plot - this is very customizable
glatos_deploy_plot <- glatos_receivers %>%
  mutate(deploy_date=ymd_hms(deploy_date_time)) %>% #make a datetime
  mutate(recover_date=ymd_hms(recover_date_time)) %>% #make a datetime
  filter(!is.na(deploy_date)) %>% #no null deploys
  filter(deploy_date > '2011-07-03' & recover_date < '2018-12-11') %>% #only looking at certain deployments, can add start/end dates here
  group_by(station, glatos_array) %>%
  summarise(MeanLat=mean(deploy_lat), MeanLong=mean(deploy_long)) #get the mean location per station, in case there is >1 deployment

# you could choose to plot stations which are within a certain bounding box!
#to do this you would add another filter to the above data, before passing to the map
# ex: add this line after the mutate() clauses:
# filter(latitude <= 0.5 & latitude >= 24.5 & longitude <= 0.6 & longitude >= 34.9)


#add your stations onto your basemap
glatos_map <-
  ggmap(base, extent='panel') +
  ylab("Latitude") +
  xlab("Longitude") +
  geom_point(data = glatos_deploy_plot, #filtering for recent deployments
             aes(x = MeanLong,y = MeanLat, colour = glatos_array), #specify the data
             shape = 19, size = 2) #lots of aesthetic options here!

#view your receiver map!
glatos_map

#save your receiver map into your working directory
ggsave(plot = glatos_map, filename = "glatos_map.tiff", units="in", width=15, height=8)
#can specify location, file type and dimensions
~~~
{: .language-r}

### Mapping our stations - Static map

This section will use the Deployment and Recovery metadata for our array, from our Workbook.
~~~
base <- get_stamenmap(
  bbox = c(left = min(walleye_recievers$DEPLOY_LONG),
           bottom = min(walleye_recievers$DEPLOY_LAT),
           right = max(walleye_recievers$DEPLOY_LONG),
           top = max(walleye_recievers$DEPLOY_LAT)),
  maptype = "terrain-background",
  crop = FALSE,
  zoom = 8)

#filter for stations you want to plot - this is very customizable
walleye_deploy_plot <- walleye_recievers %>%
  mutate(deploy_date=ymd_hms(GLATOS_DEPLOY_DATE_TIME)) %>% #make a datetime
  mutate(recover_date=ymd_hms(GLATOS_RECOVER_DATE_TIME)) %>% #make a datetime
  filter(!is.na(deploy_date)) %>% #no null deploys
  filter(deploy_date > '2011-07-03' & is.na(recover_date)) %>% #only looking at certain deployments, can add start/end dates here
  group_by(STATION_NO, GLATOS_ARRAY) %>%
  summarise(MeanLat=mean(DEPLOY_LAT), MeanLong=mean(DEPLOY_LONG)) #get the mean location per station, in case there is >1 deployment

#add your stations onto your basemap
walleye_deploy_map <-
  ggmap(base, extent='panel') +
  ylab("Latitude") +
  xlab("Longitude") +
  geom_point(data = walleye_deploy_plot, #filtering for recent deployments
             aes(x = MeanLong,y = MeanLat, colour = GLATOS_ARRAY), #specify the data
             shape = 19, size = 2) #lots of aesthetic options here!


#view your receiver map!
walleye_deploy_map

#save your receiver map into your working directory
ggsave(plot = walleye_deploy_map, filename = "walleye_deploy_map.tiff", units="in", width=15, height=8)
#can specify location, file type and dimensions
~~~
{: .language-r}

### Mapping my stations - Interactive map

An interactive map can contain more information than a static map.

~~~
library(plotly)

#set your basemap

geo_styling <- list(
  scope = usa,
  fitbounds = "locations", visible = TRUE, #fits the bounds to your data!
  showland = TRUE,
  showlakes = TRUE,
  lakecolor = toRGB("blue", alpha = 0.2), #make it transparent
  showcountries = TRUE,
  landcolor = toRGB("gray95"),
  countrycolor = toRGB("gray85")
)

#decide what data you're going to use

glatos_map_plotly <- plot_geo(glatos_deploy_plot, lat = ~MeanLat, lon = ~MeanLong)  

#add your markers for the interactive map

glatos_map_plotly <- glatos_map_plotly %>% add_markers(
  text = ~paste(station, MeanLat, MeanLong, sep = "<br />"),
  symbol = I("square"), size = I(8), hoverinfo = "text"
)

#Add layout (title + geo stying)

glatos_map_plotly <- glatos_map_plotly %>% layout(
  title = 'GLATOS Deployments<br />(> 2011-07-03)', geo = geo_styling
)

#View map

glatos_map_plotly
~~~
{: .language-r}

### How are my stations performing?

Let's find out more about the animals detected by our array!
~~~
#How many detections of my tags does each station have?

det_summary  <- all_dets  %>%
  filter(glatos_project_receiver == 'HECST') %>%  #choose to summarize by array, project etc!
  mutate(detection_timestamp_utc=ymd_hms(detection_timestamp_utc))  %>%
  group_by(station, year = year(detection_timestamp_utc), month = month(detection_timestamp_utc)) %>%
  summarize(count =n())

det_summary #number of dets per month/year per station


#How many detections of my tags does each station have? Per species

anim_summary  <- all_dets  %>%
  filter(glatos_project_receiver == 'HECST') %>%  #choose to summarize by array, project etc!
  mutate(detection_timestamp_utc=ymd_hms(detection_timestamp_utc))  %>%
  group_by(station, year = year(detection_timestamp_utc), month = month(detection_timestamp_utc), common_name_e) %>%
  summarize(count =n())

anim_summary #number of dets per month/year per station & species


~~~
{: .language-r}
