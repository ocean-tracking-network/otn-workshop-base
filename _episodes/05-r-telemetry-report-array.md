---
title: Telemetry Reports for Array Operators
teaching: 30
exercises: 0
questions:
    - "How do I summarize and plot my deployments?"
    - "How do I summarize and plot my detections?"
---

**NOTE:** this workshop has been update to align with OTN's 2025 Detection Extract Format. For older detection extracts, please see the this lesson: [Archived OTN Workshop](https://ocean-tracking-network.github.io/otn-workshop-2025-06/). 

**Note to instructors: please choose the relevant Network below when teaching**

## ACT Node

### Mapping Receiver Stations - Static map

This section will use a set of receiver metadata from the ACT Network, showing stations which may not be included in our Array. We will make a static map of all the receiver stations in three steps, using the package `ggmap`. 

First, we set a basemap using the aesthetics and bounding box we desire. Then, we will filter our stations dataset for those which we would like to plot on the map. Next, we add the stations onto the basemap and look at our creation! If we are happy with the product, we can export the map as a `.tiff` file using the `ggsave` function, to use outside of R. Other possible export formats include: `.png`, `.jpeg`, `.pdf` and more.
~~~
library(ggmap)


#We'll use the CSV below to tell where our stations and receivers are.
full_receivers <- read.csv('matos_FineToShare_stations_receivers_202104091205.csv')
full_receivers

#what are our columns called?
names(full_receivers)


#make a basemap for all of the stations, using the min/max deploy lat and longs as bounding box


base <- get_stadiamap(
  bbox = c(left = min(full_receivers$stn_long), 
           bottom = min(full_receivers$stn_lat), 
           right = max(full_receivers$stn_long), 
           top = max(full_receivers$stn_lat)),
  maptype = "stamen_terrain_background", 
  crop = FALSE,
  zoom = 6)

#filter for stations you want to plot - this is very customizable

full_receivers_plot <- full_receivers %>% 
  mutate(deploy_date=ymd(deploy_date)) %>% #make a datetime
  mutate(recovery_date=ymd(recovery_date)) %>% #make a datetime
  filter(!is.na(deploy_date)) %>% #no null deploys
  filter(deploy_date > '2011-07-03' & recovery_date < '2018-12-11') %>% #only looking at certain deployments, can add start/end dates here
  group_by(station_name) %>% 
  summarise(MeanLat=mean(stn_lat), MeanLong=mean(stn_long)) #get the mean location per station, in case there is >1 deployment

# you could choose to plot stations which are within a certain bounding box!
# to do this you would add another filter to the above data, before passing to the map
# ex: add this line after the mutate() clauses:
# filter(decimalLatitude <= 0.5 & decimalLatitude >= 24.5 & decimalLongitude <= 0.6 & decimalLongitude >= 34.9)


#add your stations onto your basemap

full_receivers_map <- 
  ggmap(base, extent='panel') + 
  ylab("Latitude") +
  xlab("Longitude") +
  geom_point(data = full_receivers_plot, #filtering for recent deployments
             aes(x = MeanLong, y = MeanLat), #specify the data
             shape = 19, size = 2) #lots of aesthetic options here!

#view your receiver map!
full_receivers_map

#save your receiver map into your working directory

ggsave(plot = full_receivers_map, filename = "full_receivers_map.tiff", units="in", width=15, height=8) 
#can specify file location, file type and dimensions
~~~
{: .language-r}

### Mapping our stations - Static map

We can do the same exact thing with the deployment metadata from OUR project only!

~~~
names(serc1_deploy)


base <- get_stadiamap(
  bbox = c(left = min(serc1_deploy$DEPLOY_LONG), 
           bottom = min(serc1_deploy$DEPLOY_LAT), 
           right = max(serc1_deploy$DEPLOY_LONG), 
           top = max(serc1_deploy$DEPLOY_LAT)),
  maptype = "stamen_terrain_background", 
  crop = FALSE,
  zoom = 5)

#filter for stations you want to plot - this is very customizable

serc1_deploy_plot <- serc1_deploy %>% 
  mutate(deploy_date=ymd_hms(`DEPLOY_DATE_TIME   (yyyy-mm-ddThh:mm:ss)`)) %>% #make a datetime
  mutate(recover_date=ymd_hms(`RECOVER_DATE_TIME (yyyy-mm-ddThh:mm:ss)`)) %>% #make a datetime
  filter(!is.na(deploy_date)) %>% #no null deploys
  filter(deploy_date > '2011-07-03' & recover_date < '2018-12-11') %>% #only looking at certain deployments, can add start/end dates here
  group_by(STATION_NO) %>% 
  summarise(MeanLat=mean(DEPLOY_LAT), MeanLong=mean(DEPLOY_LONG)) #get the mean location per station, in case there is >1 deployment


#add your stations onto your basemap

serc1_map <- 
  ggmap(base, extent='panel') + 
  ylab("Latitude") +
  xlab("Longitude") +
  geom_point(data = serc1_deploy_plot, #filtering for recent deployments
             aes(x = MeanLong,y = MeanLat, colour = STATION_NO), #specify the data
             shape = 19, size = 2) #lots of aesthetic options here!

#view your receiver map!
serc1_map

#save your receiver map into your working directory

ggsave(plot = serc1_map, filename = "serc1_map.tiff", units="in", width=15, height=8) 

#can specify location, file type and dimensions
~~~
{: .language-r}

### Mapping my stations - Interactive map

An interactive map can contain more information than a static map. Here we will explore the package `plotly` to create interactive "slippy" maps. These allow you to explore your map in different ways by clicking and scrolling through the output.

First, we will set our basemap's aesthetics and bounding box and assign this information (as a list) to a geo_styling variable.
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
~~~
{: .language-r}

Then, we choose which Deployment Metadata dataset we wish to use and identify the columns containing Latitude and Longitude, using the `plot_geo` function. 

~~~
#decide what data you're going to use. Let's use serc1_deploy_plot, which we created above for our static map.

serc1_map_plotly <- plot_geo(serc1_deploy_plot, lat = ~MeanLat, lon = ~MeanLong)   
~~~
{: .language-r}

Next, we use the `add_markers` function to write out what information we would like to have displayed when we hover our mouse over a station in our interactive map. In this case, we chose to use `paste` to join together the Station Name and its lat/long.
~~~
#add your markers for the interactive map

serc1_map_plotly <- serc1_map_plotly %>% add_markers(
  text = ~paste(STATION_NO, MeanLat, MeanLong, sep = "<br />"),
  symbol = I("square"), size = I(8), hoverinfo = "text" 
)
~~~
{: .language-r}

Finally, we add all this information together, along with a title, using the `layout` function, and now we can explore our interactive map!
~~~
#Add layout (title + geo stying)

serc1_map_plotly <- serc1_map_plotly %>% layout(
  title = 'SERC 1 Deployments<br />(> 2011-07-03)', geo = geo_styling
)

#View map

serc1_map_plotly
~~~
{: .language-r}

To save this interactive map as an `.html` file, you can explore the function htmlwidgets::saveWidget(), which is beyond the scope of this lesson.

### Summary of Animals Detected

Let's find out more about the animals detected by our array! These summary statistics, created using `dplyr` functions, could be used to help determine the how successful each of your stations has been at detecting tagged animals. We will also learn how to export our results using `write_csv`.

~~~
# How many of each animal did we detect from each collaborator, per station
library(dplyr)

serc1_qual_summary <- serc1_qual_16_17_full %>% 
  filter(dateCollectedUTC > '2016-06-01') %>% #select timeframe, stations etc.
  group_by(trackerCode, station, contactPI, contactPOC) %>% 
  summarize(count = n()) %>% 
  select(trackerCode, contactPI, contactPOC, station, count)

#view our summary table

serc1_qual_summary 

#export our summary table

write_csv(serc1_qual_summary, "serc1_summary.csv", col_names = TRUE)
~~~
{: .language-r}

### Summary of Detections

These `dplyr` summaries can suggest array performance, hotspot stations, and be used as a metric for funders.

~~~
# number of detections per month/year per station 

serc1_det_summary  <- serc1_qual_16_17_full  %>% 
  mutate(dateCollectedUTC=ymd_hms(dateCollectedUTC))  %>% 
  group_by(station, year = year(dateCollectedUTC), month = month(dateCollectedUTC)) %>% 
  summarize(count =n())

serc1_det_summary 

# Create a new data product, det_days, that give you the unique dates that an animal was seen by a station

stationsum <- serc1_qual_16_17_full %>% 
  group_by(station) %>%
  summarise(num_detections = length(dateCollectedUTC),
            start = min(dateCollectedUTC),
            end = max(dateCollectedUTC),
            uniqueIDs = length(unique(tagName)), 
            det_days=length(unique(as.Date(dateCollectedUTC))))

View(stationsum)

~~~
{: .language-r}

### Plot of Detections 

Lets make an informative plot using `ggplot` showing the number of matched detections, per year and month. Remember: we can combine `dplyr` data manipulation and plotting into one step, using pipes!

~~~
serc1_qual_16_17_full %>%  
  mutate(dateCollectedUTC=ymd_hms(dateCollectedUTC)) %>% #make datetime
  mutate(year_month = floor_date(dateCollectedUTC, "months")) %>% #round to month
  group_by(year_month) %>% #can group by station, species etc.
  summarize(count =n()) %>% #how many dets per year_month
  ggplot(aes(x = (month(year_month) %>% as.factor()), 
             y = count, 
             fill = (year(year_month) %>% as.factor())
  )
  )+ 
  geom_bar(stat = "identity", position = "dodge2")+ 
  xlab("Month")+
  ylab("Total Detection Count")+
  ggtitle('SERC1 Animal Detections by Month')+ #title
  labs(fill = "Year") #legend title
~~~
{: .language-r}



## FACT Node

### Mapping my stations - Static map

Since we have already imported and joined our datasets, we can jump in. This section will use the Deployment metadata for your array. We will make a static map of all the receiver stations in three steps, using the package `ggmap`. 

First, we set a basemap using the aesthetics and bounding box we desire. Then, we will filter our stations dataset for those which we would like to plot on the map. Next, we add the stations onto the basemap and look at our creation! If we are happy with the product, we can export the map as a `.tiff` file using the `ggsave` function, to use outside of R. Other possible export formats include: `.png`, `.jpeg`, `.pdf` and more.
~~~
library(ggmap)


#first, what are our columns called?
names(teq_deploy)


#make a basemap for your stations, using the min/max deploy lat and longs as bounding box

base <- get_stadiamap(
  bbox = c(left = min(teq_deploy$DEPLOY_LONG), 
           bottom = min(teq_deploy$DEPLOY_LAT), 
           right = max(teq_deploy$DEPLOY_LONG), 
           top = max(teq_deploy$DEPLOY_LAT)),
  maptype = "stamen_terrain_background", 
  crop = FALSE,
  zoom = 8)

#filter for stations you want to plot

teq_deploy_plot <- teq_deploy %>% 
  dplyr::mutate(deploy_date=ymd_hms(DEPLOY_DATE_TIME....yyyy.mm.ddThh.mm.ss.)) %>% #make a datetime
  dplyr::mutate(recover_date=ymd_hms(RECOVER_DATE_TIME..yyyy.mm.ddThh.mm.ss.)) %>% #make a datetime
  dplyr::filter(!is.na(deploy_date)) %>% #no null deploys
  dplyr::filter(deploy_date > 2010-07-03) %>% #only looking at certain deployments!
  dplyr::group_by(STATION_NO) %>% 
  dplyr::summarise(MeanLat=mean(DEPLOY_LAT), MeanLong=mean(DEPLOY_LONG)) #get the mean location per station
  
# you could choose to plot stations which are within a certain bounding box!
# to do this you would add another filter to the above data, before passing to the map
# ex: add this line after the mutate() clauses:
	# filter(decimalLatitude >= 0.5 & decimalLatitude <= 24.5 & decimalLongitude >= 0.6 & decimalLongitude <= 34.9)


#add your stations onto your basemap

teq_map <- 
  ggmap(base, extent='panel') +
  ylab("Latitude") +
  xlab("Longitude") +
  geom_point(data = teq_deploy_plot, #filtering for recent deployments
             aes(x = MeanLong,y = MeanLat), #specify the data
             colour = 'blue', shape = 19, size = 2) #lots of aesthetic options here!

#view your receiver map!

teq_map

#save your receiver map into your working directory

ggsave(plot = teq_map, file = "code/day1/teq_map.tiff", units="in", width=15, height=8)
~~~
{: .language-r}

### Mapping my stations - Interactive map

An interactive map can contain more information than a static map. Here we will explore the package `plotly` to create interactive "slippy" maps. These allow you to explore your map in different ways by clicking and scrolling through the output.

First, we will set our basemap's aesthetics and bounding box and assign this information (as a list) to a geo_styling variable.

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

~~~
{: .language-r}

Then, we choose which Deployment Metadata dataset we wish to use and identify the columns containing Latitude and Longitude, using the `plot_geo` function.
~~~
#decide what data you're going to use. Let's use teq_deploy_plot, which we created above for our static map.

teq_map_plotly <- plot_geo(teq_deploy_plot, lat = ~MeanLat, lon = ~MeanLong)  
~~~
{: .language-r}

Next, we use the `add_markers` function to write out what information we would like to have displayed when we hover our mouse over a station in our interactive map. In this case, we chose to use `paste` to join together the Station Name and its lat/long. 
~~~
#add your markers for the interactive map

teq_map_plotly <- teq_map_plotly %>% add_markers(
  text = ~paste(STATION_NO, MeanLat, MeanLong, sep = "<br />"),
  symbol = I("square"), size = I(8), hoverinfo = "text" 
)
~~~
{: .language-r}

Finally, we add all this information together, along with a title, using the `layout` function, and now we can explore our interactive map!
~~~
#Add layout (title + geo stying)

teq_map_plotly <- teq_map_plotly %>% layout(
  title = 'TEQ Deployments<br />(> 2010-07-03)', geo = geo_styling
)

#View map

teq_map_plotly

~~~
{: .language-r}

To save this interactive map as an `.html` file, you can explore the function htmlwidgets::saveWidget(), which is beyond the scope of this lesson.
 
### Summary of Animals Detected

Let's find out more about the animals detected by our array! These summary statistics, created using `dplyr` functions, could be used to help determine the how successful each of your stations has been at detecting tagged animals. We will also learn how to export our results using `write_csv`.

~~~
# How many of each animal did we detect from each collaborator, by species

library(dplyr)

teq_qual_summary <- teq_qual_10_11 %>% 
  filter(dateCollectedUTC > '2010-06-01') %>% #select timeframe, stations etc.
  group_by(trackerCode, scientificName, contactPI, contactPOC) %>% 
  summarize(count = n()) %>% 
  select(trackerCode, contactPI, contactPOC, scientificName, count)

#view our summary table

teq_qual_summary #remember, this is just the first 100,000 rows! We subsetted the dataset upon import!

#export our summary table

write_csv(teq_qual_summary, "teq_detection_summary_June2010_to_Dec2011.csv", col_names = TRUE)

~~~
{: .language-r}

You may notice in your summary table above that some rows have a value of `NA` for 'scientificname'. This is because this example dataset has detections of animals tagged by researchers who are not a part of the FACT Network, and therefore have not agreed to share their species information with array-operators automatically. To obtain this information you would have to reach out to the researcher directly. For more information on the FACT Data Policy and how it differs from other collaborating OTN Networks, please reach out to Data@theFACTnetwork.org.


### Summary of Detections

These `dplyr` summaries can suggest array performance, hotspot stations, and be used as a metric for funders.

~~~
# number of detections per month/year per station 

teq_det_summary  <- teq_qual_10_11  %>% 
  group_by(station, year = year(dateCollectedUTC), month = month(dateCollectedUTC)) %>% 
  summarize(count =n())

teq_det_summary #remember: this is a subset!

# number of detections per month/year per station & species

teq_anim_summary  <- teq_qual_10_11  %>%  
  group_by(station, year = year(dateCollectedUTC), month = month(dateCollectedUTC), scientificName) %>% 
  summarize(count =n())

teq_anim_summary # remember: this is a subset!

# Create a new data product, det_days, that give you the unique dates that an animal was seen by a station
stationsum <- teq_qual_10_11 %>% 
  group_by(station) %>%
  summarise(num_detections = length(dateCollectedUTC),
            start = min(dateCollectedUTC),
            end = max(dateCollectedUTC),
            species = length(unique(scientificName)),
            uniqueIDs = length(unique(tagName)), 
            det_days=length(unique(as.Date(dateCollectedUTC))))
View(stationsum)


~~~
{: .language-r}

### Plot of Detections

Lets make an informative plot using `ggplot` showing the number of matched detections, per year and month. Remember: we can combine `dplyr` data manipulation and plotting into one step, using pipes!

~~~
#try with teq_qual_10_11_full if you're feeling bold! takes about 1 min to run on a fast machine

teq_qual_10_11 %>% 
  mutate(dateCollectedUTC=as.POSIXct(dateCollectedUTC)) %>% #make datetime
  mutate(year_month = floor_date(dateCollectedUTC, "months")) %>% #round to month
  group_by(year_month) %>% #can group by station, species etc.
  summarize(count =n()) %>% #how many dets per year_month
  ggplot(aes(x = (month(year_month) %>% as.factor()), 
             y = count, 
             fill = (year(year_month) %>% as.factor())
  )
  )+ 
  geom_bar(stat = "identity", position = "dodge2")+ 
  xlab("Month")+
  ylab("Total Detection Count")+
  ggtitle('TEQ Animal Detections by Month')+ #title
  labs(fill = "Year") #legend title

~~~
{: .language-r}


## GLATOS Network

### Mapping GLATOS stations - Static map

This section will use a set of receiver metadata from the GLATOS Network, showing stations which may not be included in our Project. We will make a static map of all the receiver stations in three steps, using the package `ggmap`. 

First, we set a basemap using the aesthetics and bounding box we desire. Then, we will filter our stations dataset for those which we would like to plot on the map. Next, we add the stations onto the basemap and look at our creation! If we are happy with the product, we can export the map as a `.tiff` file using the `ggsave` function, to use outside of R. Other possible export formats include: `.png`, `.jpeg`, `.pdf` and more.
~~~
library(ggmap)


#first, what are our columns called?
names(glatos_receivers)


#make a basemap for all of the stations, using the min/max deploy lat and longs as bounding box

base <- get_stadiamap(
  bbox = c(left = min(glatos_receivers$deploy_long), 
           bottom = min(glatos_receivers$deploy_lat), 
           right = max(glatos_receivers$deploy_long), 
           top = max(glatos_receivers$deploy_lat)),
  maptype = "stamen_terrain_background", 
  crop = FALSE,
  zoom = 8)

#filter for stations you want to plot - this is very customizable

glatos_deploy_plot <- glatos_receivers %>% 
  dplyr::mutate(deploy_date=ymd_hms(deploy_date_time)) %>% #make a datetime
  dplyr::mutate(recover_date=ymd_hms(recover_date_time)) %>% #make a datetime
  dplyr::filter(!is.na(deploy_date)) %>% #no null deploys
  dplyr::filter(deploy_date > '2011-07-03' & recover_date < '2018-12-11') %>% #only looking at certain deployments, can add start/end dates here
  dplyr::group_by(station, glatos_array) %>% 
  dplyr::summarise(MeanLat=mean(deploy_lat), MeanLong=mean(deploy_long)) #get the mean location per station, in case there is >1 deployment

# you could choose to plot stations which are within a certain bounding box!
#to do this you would add another filter to the above data, before passing to the map
# ex: add this line after the mutate() clauses:
# filter(decimalLatitude <= 0.5 & decimalLatitude >= 24.5 & decimalLongitude <= 0.6 & decimalLongitude >= 34.9)


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

We can do the same exact thing with the deployment metadata from OUR project only! This will use metadata imported from our Workbook.

~~~
base <- get_stadiamap(
  bbox = c(left = min(walleye_recievers$DEPLOY_LONG), 
           bottom = min(walleye_recievers$DEPLOY_LAT), 
           right = max(walleye_recievers$DEPLOY_LONG), 
           top = max(walleye_recievers$DEPLOY_LAT)),
  maptype = "stamen_terrain_background", 
  crop = FALSE,
  zoom = 8)

#filter for stations you want to plot - this is very customizable

walleye_deploy_plot <- walleye_recievers %>% 
  dplyr::mutate(deploy_date=ymd_hms(GLATOS_DEPLOY_DATE_TIME)) %>% #make a datetime
  dplyr::mutate(recover_date=ymd_hms(GLATOS_RECOVER_DATE_TIME)) %>% #make a datetime
  dplyr::filter(!is.na(deploy_date)) %>% #no null deploys
  dplyr::filter(deploy_date > '2011-07-03' & is.na(recover_date)) %>% #only looking at certain deployments, can add start/end dates here
  dplyr::group_by(STATION_NO, GLATOS_ARRAY) %>% 
  dplyr::summarise(MeanLat=mean(DEPLOY_LAT), MeanLong=mean(DEPLOY_LONG)) #get the mean location per station, in case there is >1 deployment

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

### Mapping all GLATOS Stations - Interactive map

An interactive map can contain more information than a static map. Here we will explore the package `plotly` to create interactive "slippy" maps. These allow you to explore your map in different ways by clicking and scrolling through the output.

First, we will set our basemap's aesthetics and bounding box and assign this information (as a list) to a geo_styling variable.  

~~~
library(plotly)

#set your basemap

geo_styling <- list(
  fitbounds = "locations", visible = TRUE, #fits the bounds to your data!
  showland = TRUE,
  showlakes = TRUE,
  lakecolor = toRGB("blue", alpha = 0.2), #make it transparent
  showcountries = TRUE,
  landcolor = toRGB("gray95"),
  countrycolor = toRGB("gray85")
)
~~~
{: .language-r}

Then, we choose which Deployment Metadata dataset we wish to use and identify the columns containing Latitude and Longitude, using the `plot_geo` function.
~~~
#decide what data you're going to use. We have chosen glatos_deploy_plot which we created earlier.

glatos_map_plotly <- plot_geo(glatos_deploy_plot, lat = ~MeanLat, lon = ~MeanLong)  
~~~
{: .language-r}

Next, we use the `add_markers` function to write out what information we would like to have displayed when we hover our mouse over a station in our interactive map. In this case, we chose to use `paste` to join together the Station Name and its lat/long.
~~~
#add your markers for the interactive map

glatos_map_plotly <- glatos_map_plotly %>% add_markers(
  text = ~paste(station, MeanLat, MeanLong, sep = "<br />"),
  symbol = I("square"), size = I(8), hoverinfo = "text" 
)
~~~
{: .language-r}

Finally, we add all this information together, along with a title, using the `layout` function, and now we can explore our interactive map!
~~~
#Add layout (title + geo stying)

glatos_map_plotly <- glatos_map_plotly %>% layout(
  title = 'GLATOS Deployments<br />(> 2011-07-03)', geo = geo_styling
)

#View map

glatos_map_plotly
~~~
{: .language-r}

To save this interactive map as an `.html` file, you can explore the function htmlwidgets::saveWidget(), which is beyond the scope of this lesson.

### How are my stations performing?

Let's find out more about the animals detected by our array! These summary statistics, created using `dplyr` functions, could be used to help determine the how successful each of your stations has been at detecting your tagged animals. We will also learn how to export our results using `write_csv`.

~~~
#How many detections of my tags does each station have?

library(dplyr)

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

# Create a new data product, det_days, that give you the unique dates that an animal was seen by a station
stationsum <- all_dets %>% 
  group_by(station) %>%
  summarise(num_detections = length(animal_id),
            start = min(detection_timestamp_utc),
            end = max(detection_timestamp_utc),
            uniqueIDs = length(unique(animal_id)), 
            det_days=length(unique(as.Date(detection_timestamp_utc))))
View(stationsum)

~~~
{: .language-r}

## MigraMar Node

### Mapping our stations - Static map

This section will use a set of receiver metadata from the MigraMar Network, showing stations which are included in our Array. We will make a static map of all the receiver stations in three steps, using the package `ggmap`. 

First, we set a basemap using the aesthetics and bounding box we desire. Then, we will filter our stations dataset for those which we would like to plot on the map. Next, we add the stations onto the basemap and look at our creation! If we are happy with the product, we can export the map as a `.tiff` file using the `ggsave` function, to use outside of R. Other possible export formats include: `.png`, `.jpeg`, `.pdf` and more.
~~~
library(ggmap)

names(gmr_deploy)

base <- get_stadiamap(
  bbox = c(left = min(gmr_deploy$DEPLOY_LONG),
           bottom = min(gmr_deploy$DEPLOY_LAT),
           right = max(gmr_deploy$DEPLOY_LONG),
           top = max(gmr_deploy$DEPLOY_LAT)),
  maptype = "stamen_terrain",
  crop = FALSE,
  zoom = 12)

#filter for stations you want to plot - this is very customizable

gmr_deploy_plot <- gmr_deploy %>% 
  dplyr::mutate(deploy_date=ymd_hms(`DEPLOY_DATE_TIME   (yyyy-mm-ddThh:mm:ss)`)) %>% #make a datetime
  dplyr::mutate(recover_date=ymd_hms(`RECOVER_DATE_TIME (yyyy-mm-ddThh:mm:ss)`)) %>% #make a datetime
  dplyr::filter(!is.na(deploy_date)) %>% #no null deploys
  dplyr::filter(deploy_date > '2017-07-03') %>% #only looking at certain deployments, can add start/end dates here
  dplyr::group_by(STATION_NO) %>% 
  dplyr::summarise(MeanLat=mean(DEPLOY_LAT), MeanLong=mean(DEPLOY_LONG)) #get the mean location per station, in case there is >1 deployment


#add your stations onto your basemap

gmr_map <- 
  ggmap(base) + 
  ylab("Latitude") +
  xlab("Longitude") +
  geom_point(data = gmr_deploy_plot, #filtering for recent deployments
             aes(x = MeanLong,y = MeanLat, colour = STATION_NO), #specify the data
             shape = 19, size = 2, alpha = 1) #lots of aesthetic options here!

#view your receiver map!
gmr_map

#save your receiver map into your working directory

ggsave(plot = gmr_map, filename = "gmr_map.tiff", units="in", width=8, height=15) 

#can specify location, file type and dimensions
~~~
{: .language-r}

### Mapping my stations - Interactive map

An interactive map can contain more information than a static map. Here we will explore the package `plotly` to create interactive "slippy" maps. These allow you to explore your map in different ways by clicking and scrolling through the output.

First, we will set our basemap's aesthetics and bounding box and assign this information (as a list) to a geo_styling variable.
~~~
library(plotly)

#set your basemap

geo_styling <- list(
  scope = 'galapagos',
  #fitbounds = "locations", visible = TRUE, #fits the bounds to your data!
  showland = TRUE,
  showlakes = TRUE,
  lakecolor = toRGB("blue", alpha = 0.2), #make it transparent
  showcountries = TRUE,
  landcolor = toRGB("gray95"),
  countrycolor = toRGB("gray85"),
  lonaxis = list(
    showgrid = TRUE,
    range = c(-92.5, -90)),
  lataxis = list(
    showgrid = TRUE,
    range = c(0, 2)),
  resolution = 50
)
~~~
{: .language-r}

Then, we choose which Deployment Metadata dataset we wish to use and identify the columns containing Latitude and Longitude, using the `plot_geo` function. 

~~~
#decide what data you're going to use. Let's use gmr_deploy_plot, which we created above for our static map.

gmr_map_plotly <- plot_geo(gmr_deploy_plot, lat = ~MeanLat, lon = ~MeanLong)   
~~~
{: .language-r}

Next, we use the `add_markers` function to write out what information we would like to have displayed when we hover our mouse over a station in our interactive map. In this case, we chose to use `paste` to join together the Station Name and its lat/long.
~~~
#add your markers for the interactive map

gmr_map_plotly <- gmr_map_plotly %>% add_markers(
  text = ~paste(STATION_NO, MeanLat, MeanLong, sep = "<br />"),
  symbol = I("square"), size = I(8), hoverinfo = "text" 
)
~~~
{: .language-r}

Finally, we add all this information together, along with a title, using the `layout` function, and now we can explore our interactive map!
~~~
#Add layout (title + geo stying)

gmr_map_plotly <- gmr_map_plotly %>% layout(
  title = 'GMR Deployments<br />(> 2017-07-03)', geo = geo_styling)


#View map

gmr_map_plotly
~~~
{: .language-r}

To save this interactive map as an `.html` file, you can explore the function htmlwidgets::saveWidget(), which is beyond the scope of this lesson.

### Summary of Animals Detected

Let's find out more about the animals detected by our array! These summary statistics, created using `dplyr` functions, could be used to help determine the how successful each of your stations has been at detecting tagged animals. We will also learn how to export our results using `write_csv`.

~~~
# How many of each animal did we detect from each collaborator, per station
library(dplyr) #to ensure no functions have been masked by plotly

gmr_qual_summary <- gmr_qual_18_19 %>% 
  dplyr::filter(dateCollectedUTC > '2018-06-01') %>% #select timeframe, stations etc.
  dplyr::group_by(trackerCode, station, contactPI, contactPOC) %>% 
  dplyr::summarize(count = n()) %>% 
  dplyr::select(trackerCode, contactPI, contactPOC, station, count)

#view our summary table

gmr_qual_summary #reminder: this is filtered for certain dates!

#export our summary table

write_csv(gmr_qual_summary, "gmr_array_summary.csv", col_names = TRUE)
~~~
{: .language-r}

### Summary of Detections

These `dplyr` summaries can suggest array performance, hotspot stations, and be used as a metric for funders.

~~~
# number of detections per month/year per station 

gmr_det_summary  <- gmr_qual_18_19  %>% 
  mutate(dateCollectedUTC=ymd_hms(dateCollectedUTC))  %>% 
  group_by(station, year = year(dateCollectedUTC), month = month(dateCollectedUTC)) %>% 
  summarize(count =n())

gmr_det_summary 


# Create a new data product, det_days, that give you the unique dates that an animal was seen by a station
stationsum <- gmr_qual_18_19 %>% 
  group_by(station) %>%
  summarise(num_detections = length(dateCollectedUTC),
            start = min(dateCollectedUTC),
            end = max(dateCollectedUTC),
            uniqueIDs = length(unique(tagName)), 
            det_days=length(unique(as.Date(dateCollectedUTC))))
view(stationsum)

~~~
{: .language-r}

### Plot of Detections 

Lets make an informative plot using `ggplot` showing the number of matched detections, per year and month. Remember: we can combine `dplyr` data manipulation and plotting into one step, using pipes!

~~~

gmr_qual_18_19 %>%  
  mutate(dateCollectedUTC=ymd_hms(dateCollectedUTC)) %>% #make datetime
  mutate(year_month = floor_date(dateCollectedUTC, "months")) %>% #round to month
  group_by(year_month) %>% #can group by station, collaborator etc.
  summarize(count =n()) %>% #how many dets per year_month
  ggplot(aes(x = (month(year_month) %>% as.factor()), 
             y = count, 
             fill = (year(year_month) %>% as.factor())
  )
  )+ 
  geom_bar(stat = "identity", position = "dodge2")+ 
  xlab("Month")+
  ylab("Total Detection Count")+
  ggtitle('GMR Collected Detections by Month')+ #title
  labs(fill = "Year") #legend title

~~~
{: .language-r}

## OTN Node

### Mapping our stations - Static map

We can do the same exact thing with the deployment metadata from OUR project only!

~~~
names(hfx_deploy)

base <- get_stadiamap(
  bbox = c(left = min(hfx_deploy$DEPLOY_LONG), 
           bottom = min(hfx_deploy$DEPLOY_LAT), 
           right = max(hfx_deploy$DEPLOY_LONG), 
           top = max(hfx_deploy$DEPLOY_LAT)),
  maptype = "stamen_toner_lite", 
  crop = FALSE,
  zoom = 5)


#filter for stations you want to plot - this is very customizable

hfx_deploy_plot <- hfx_deploy %>% 
  mutate(deploy_date=ymd_hms(`DEPLOY_DATE_TIME   (yyyy-mm-ddThh:mm:ss)`)) %>% #make a datetime
  mutate(recover_date=ymd_hms(`RECOVER_DATE_TIME (yyyy-mm-ddThh:mm:ss)`)) %>% #make a datetime
  filter(!is.na(deploy_date)) %>% #no null deploys
  filter(deploy_date > '2020-07-03' | recover_date < '2022-01-11') %>% #only looking at certain deployments, can add start/end dates here
  group_by(STATION_NO) %>% 
  summarise(MeanLat=mean(DEPLOY_LAT), MeanLong=mean(DEPLOY_LONG)) #get the mean location per station, in case there is >1 deployment


#add your stations onto your basemap

hfx_map <- 
  ggmap(base, extent='panel') + 
  ylab("Latitude") +
  xlab("Longitude") +
  geom_point(data = hfx_deploy_plot, #filtering for recent deployments
             aes(x = MeanLong,y = MeanLat), #specify the data, colour = STATION_NO is also neat here
             shape = 19, size = 2) #lots of aesthetic options here!

#view your receiver map!
hfx_map

#save your receiver map into your working directory

ggsave(plot = hfx_map, filename = "hfx_map.tiff", units="in", width=15, height=8) 

#can specify location, file type and dimensions
~~~
{: .language-r}

### Mapping my stations - Interactive map

An interactive map can contain more information than a static map. Here we will explore the package `plotly` to create interactive "slippy" maps. These allow you to explore your map in different ways by clicking and scrolling through the output.

First, we will set our basemap's aesthetics and bounding box and assign this information (as a list) to a geo_styling variable.
~~~
library(plotly)

#set your basemap

geo_styling <- list(
  scope = 'nova scotia',
  fitbounds = "locations", visible = TRUE, #fits the bounds to your data!
  showland = TRUE,
  showlakes = TRUE,
  lakecolor = toRGB("blue", alpha = 0.2), #make it transparent
  showcountries = TRUE,
  landcolor = toRGB("gray95"),
  countrycolor = toRGB("gray85")
)

~~~
{: .language-r}

Then, we choose which Deployment Metadata dataset we wish to use and identify the columns containing Latitude and Longitude, using the `plot_geo` function. 

~~~
#decide what data you're going to use. Let's use hfx_deploy_plot, which we created above for our static map.

hfx_map_plotly <- plot_geo(hfx_deploy_plot, lat = ~MeanLat, lon = ~MeanLong)  
~~~
{: .language-r}

Next, we use the `add_markers` function to write out what information we would like to have displayed when we hover our mouse over a station in our interactive map. In this case, we chose to use `paste` to join together the Station Name and its lat/long.
~~~
#add your markers for the interactive map

hfx_map_plotly <- hfx_map_plotly %>% add_markers(
  text = ~paste(STATION_NO, MeanLat, MeanLong, sep = "<br />"),
  symbol = I("square"), size = I(8), hoverinfo = "text" 
)
~~~
{: .language-r}

Finally, we add all this information together, along with a title, using the `layout` function, and now we can explore our interactive map!
~~~
#Add layout (title + geo stying)

hfx_map_plotly <- hfx_map_plotly %>% layout(
  title = 'HFX Deployments<br />(> 2020-07-03)', geo = geo_styling 
)

#View map

hfx_map_plotly
~~~
{: .language-r}

To save this interactive map as an `.html` file, you can explore the function htmlwidgets::saveWidget(), which is beyond the scope of this lesson.

### Summary of Animals Detected

Let's find out more about the animals detected by our array! These summary statistics, created using `dplyr` functions, could be used to help determine the how successful each of your stations has been at detecting tagged animals. We will also learn how to export our results using `write_csv`.

~~~
# How many of each animal did we detect from each collaborator, per station
library(dplyr)

hfx_qual_summary <- hfx_qual_21_22_full %>% 
  filter(dateCollectedUTC > '2021-06-01') %>% #select timeframe, stations etc.
  group_by(trackerCode, station, contactPI, contactPOC) %>% 
  summarize(count = n()) %>% 
  dplyr::select(trackerCode, contactPI, contactPOC, station, count)


#view our summary table

view(hfx_qual_summary) 

#export our summary table

write_csv(hfx_qual_summary, "hfx_summary.csv", col_names = TRUE)
~~~
{: .language-r}

### Summary of Detections

These `dplyr` summaries can suggest array performance, hotspot stations, and be used as a metric for funders.

~~~
# number of detections per month/year per station 

hfx_det_summary  <- hfx_qual_21_22_full  %>% 
  mutate(dateCollectedUTC=ymd_hms(dateCollectedUTC))  %>% 
  group_by(station, year = year(dateCollectedUTC), month = month(dateCollectedUTC)) %>% 
  summarize(count =n())

hfx_det_summary 

# Create a new data product, det_days, that give you the unique dates that an animal was seen by a station
stationsum <- hfx_qual_21_22_full %>% 
  group_by(station) %>%
  summarise(num_detections = length(dateCollectedUTC),
            start = min(dateCollectedUTC),
            end = max(dateCollectedUTC),
            uniqueIDs = length(unique(tagName)), 
            det_days=length(unique(as.Date(dateCollectedUTC))))
View(stationsum)

~~~
{: .language-r}

### Plot of Detections 

Lets make an informative plot using `ggplot` showing the number of matched detections, per year and month. Remember: we can combine `dplyr` data manipulation and plotting into one step, using pipes!

~~~

hfx_qual_21_22_full %>%  
  mutate(dateCollectedUTC=ymd_hms(dateCollectedUTC)) %>% #make datetime
  mutate(year_month = floor_date(dateCollectedUTC, "months")) %>% #round to month
  group_by(year_month) %>% #can group by station, species etc.
  summarize(count =n()) %>% #how many dets per year_month
  ggplot(aes(x = (month(year_month) %>% as.factor()), 
             y = count, 
             fill = (year(year_month) %>% as.factor())
  )
  )+ 
  geom_bar(stat = "identity", position = "dodge2")+ 
  xlab("Month")+
  ylab("Total Detection Count")+
  ggtitle('HFX Animal Detections by Month')+ #title
  labs(fill = "Year") #legend title
~~~
{: .language-r}
