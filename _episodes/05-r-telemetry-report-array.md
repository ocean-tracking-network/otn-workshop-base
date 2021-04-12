---
title: Telemetry Reports for Array Operators
teaching: 30
exercises: 0
questions:
    - "How do I summarize and plot my deployments?"
    - "How do I summarize and plot my detections?"
---

### Mapping Receiver Stations - Static map

This section will use a set of receiver metadata from the ACT Network.
~~~
library(ggmap)


#We'll use the CSV below to tell where our stations and receivers are.
full_receivers = read.csv('matos_FineToShare_stations_receivers_202104091205.csv')
full_receivers

#what are our columns called?
names(full_receivers)


#make a basemap for all of the stations, using the min/max deploy lat and longs as bounding box



base <- get_stamenmap(
  bbox = c(left = min(full_receivers$station_long), 
           bottom = min(full_receivers$station_lat), 
           right = max(full_receivers$station_long), 
           top = max(full_receivers$station_lat)),
  maptype = "terrain-background", 
  crop = FALSE,
  zoom = 8)

#filter for stations you want to plot - this is very customizable

full_receivers_plot <- full_receivers %>% 
  mutate(deploy_date=ymd(deploy_date)) %>% #make a datetime
  mutate(recovery_date=ymd(recovery_date)) %>% #make a datetime
  filter(!is.na(deploy_date)) %>% #no null deploys
  filter(deploy_date > '2011-07-03' & recovery_date < '2018-12-11') %>% #only looking at certain deployments, can add start/end dates here
  group_by(station_name) %>% 
  summarise(MeanLat=mean(station_lat), MeanLong=mean(station_long)) #get the mean location per station, in case there is >1 deployment

# you could choose to plot stations which are within a certain bounding box!
#to do this you would add another filter to the above data, before passing to the map
# ex: add this line after the mutate() clauses:
# filter(latitude <= 0.5 & latitude >= 24.5 & longitude <= 0.6 & longitude >= 34.9)


#add your stations onto your basemap

full_receivers_map <- 
  ggmap(base, extent='panel') + 
  ylab("Latitude") +
  xlab("Longitude") +
  geom_point(data = full_receivers_plot, #filtering for recent deployments
             aes(x = MeanLong,y = MeanLat, colour = station_name), #specify the data
             shape = 19, size = 2) #lots of aesthetic options here!

#view your receiver map!
full_receivers_map

#save your receiver map into your working directory

ggsave(plot = proj61_map, filename = "proj61_map.tiff", units="in", width=15, height=8) 
#can specify location, file type and dimensions
~~~
{: .language-r}

### Mapping our stations - Static map

We can do the same exact thing with the deployment metadata from OUR project only!

~~~

names(proj61_deploy)


base <- get_stamenmap(
  bbox = c(left = min(proj61_deploy$DEPLOY_LONG), 
           bottom = min(proj61_deploy$DEPLOY_LAT), 
           right = max(proj61_deploy$DEPLOY_LONG), 
           top = max(proj61_deploy$DEPLOY_LAT)),
  maptype = "terrain-background", 
  crop = FALSE,
  zoom = 8)

#filter for stations you want to plot - this is very customizable

proj61_deploy_plot <- proj61_deploy %>% 
  mutate(deploy_date=ymd_hms(`DEPLOY_DATE_TIME   (yyyy-mm-ddThh:mm:ss)`)) %>% #make a datetime
  mutate(recover_date=ymd_hms(`RECOVER_DATE_TIME (yyyy-mm-ddThh:mm:ss)`)) %>% #make a datetime
  filter(!is.na(deploy_date)) %>% #no null deploys
  filter(deploy_date > '2011-07-03' & recover_date < '2018-12-11') %>% #only looking at certain deployments, can add start/end dates here
  group_by(STATION_NO) %>% 

  summarise(MeanLat=mean(DEPLOY_LAT), MeanLong=mean(DEPLOY_LONG)) #get the mean location per station, in case there is >1 deployment


#add your stations onto your basemap

proj61_map <- 
  ggmap(base, extent='panel') + 
  ylab("Latitude") +
  xlab("Longitude") +
  geom_point(data = proj61_deploy_plot, #filtering for recent deployments
             aes(x = MeanLong,y = MeanLat, colour = STATION_NO), #specify the data
             shape = 19, size = 2) #lots of aesthetic options here!

#view your receiver map!
proj61_map

#save your receiver map into your working directory

ggsave(plot = proj61_map, filename = "proj61_map.tiff", units="in", width=15, height=8) 

#can specify location, file type and dimensions
~~~
{: .language-r}

### Mapping my stations - Interactive map

An interactive map can contain more information than a static map.

~~~
library(plotly)

#set your basemap

geo_styling <- list(
  scope = 'usa',
  fitbounds = "locations", visible = TRUE, #fits the bounds to your data!
  showland = TRUE,
  showlakes = TRUE,
  lakecolor = toRGB("blue", alpha = 0.2), #make it transparent
  showcountries = TRUE,
  landcolor = toRGB("gray95"),
  countrycolor = toRGB("gray85")
)

#decide what data you're going to use

proj61_map_plotly <- plot_geo(proj61_deploy_plot, lat = ~MeanLat, lon = ~MeanLong)  

#add your markers for the interactive map

proj61_map_plotly <- proj61_map_plotly %>% add_markers(
  text = ~paste(STATION_NO, MeanLat, MeanLong, sep = "<br />"),
  symbol = I("square"), size = I(8), hoverinfo = "text" 
)

#Add layout (title + geo stying)
proj61_map_plotly <- proj61_map_plotly %>% layout(
  title = 'Project 61 Deployments<br />(> 2011-07-03)', geo = geo_styling
)

#View map
proj61_map_plotly
~~~
{: .language-r}

### How are my stations performing?

Let's find out more about the animals detected by our array!
~~~
#How many detections of my tags does each station have?

proj61_qual_summary <- proj61_qual_16_17_full %>% 
  filter(datecollected > '2010-06-01') %>% #select timeframe, stations etc.
  group_by(trackercode, station, tag_contact_pi, tag_contact_poc) %>% 
  summarize(count = n()) %>% 
  select(trackercode, tag_contact_pi, tag_contact_poc, station, count)

#view our summary table

proj61_qual_summary #remember, this is just the first 10,000 rows!

#export our summary table

write_csv(proj61_qual_summary, "data/proj61_summary.csv", col_names = TRUE)
~~~
{: .language-r}
