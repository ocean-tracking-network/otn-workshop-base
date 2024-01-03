---
title: Telemetry Reports for Tag Owners
teaching: 30
exercises: 0
questions:
    - "How do I summarize and plot my detections?"
    - "How do I summarize and plot my tag metadata?"
---

**Note to instructors: please choose the relevant Network below when teaching**

## ACT Node

### New dataframes

To aid in the creating of useful Matched Detection summaries, we should create a new dataframe where we filter out release records from the detection extracts. This will leave only "true" detections.

~~~
#optional dataset to use: detections with releases filtered out!

proj58_matched_full_no_release <- proj58_matched_full  %>% 
  filter(receiver != "release")
~~~
{: .language-r}


### Mapping my Detections and Releases - static map

Where were my fish observed? We will make a static map of all the receiver stations where my fish was detected in two steps, using the package `ggmap`.

First, we set a basemap using the aesthetics and bounding box we desire. Next, we add the detection locations onto the basemap and look at our creation! 

~~~
base <- get_stadiamap(
  bbox = c(left = min(proj58_matched_full_no_release$longitude),
           bottom = min(proj58_matched_full_no_release$latitude), 
           right = max(proj58_matched_full_no_release$longitude), 
           top = max(proj58_matched_full_no_release$latitude)),
  maptype = "stamen_terrain_background", 
  crop = FALSE,
  zoom = 5)


#add your releases and detections onto your basemap

proj58_map <- 
  ggmap(base, extent='panel') +
  ylab("Latitude") +
  xlab("Longitude") +
  geom_point(data = proj58_matched_full_no_release, 
             aes(x = longitude,y = latitude), #specify the data
             colour = 'blue', shape = 19, size = 2) #lots of aesthetic options here!

#view your tagging map!

proj58_map

~~~
{: .language-r}

### Mapping my Detections and Releases - interactive map

An interactive map can contain more information than a static map. Here we will explore the package `plotly` to create interactive "slippy" maps. These allow you to explore your map in different ways by clicking and scrolling through the output.

First, we will set our basemap's aesthetics and bounding box and assign this information (as a list) to a geo_styling variable. Then, we choose which detections we wish to use and identify the columns containing Latitude and Longitude, using the `plot_geo` function. Next, we use the `add_markers` function to write out what information we would like to have displayed when we hover our mouse over a station in our interactive map. In this case, we chose to use `paste` to join together the Station Name and its lat/long. Finally, we add all this information together, along with a title, using the `layout` function, and now we can explore our interactive map!

~~~
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

#decide what data you're going to use

detections_map_plotly <- plot_geo(proj58_matched_full_no_release, lat = ~latitude, lon = ~longitude) 

#add your markers for the interactive map
detections_map_plotly <- detections_map_plotly %>% add_markers(
  text = ~paste(catalognumber, commonname, paste("Date detected:", datecollected), 
                paste("Latitude:", latitude), paste("Longitude",longitude), 
                paste("Detected by:", detectedby), paste("Station:", station), 
                paste("Project:",collectioncode), sep = "<br />"),
  symbol = I("square"), size = I(8), hoverinfo = "text" 
)

#Add layout (title + geo stying)

detections_map_plotly <- detections_map_plotly %>% layout(
  title = 'Project 58 Detections', geo = geo_styling
)

#View map
detections_map_plotly
~~~
{: .language-r}

### Summary of tagged animals

This section will use your Tagging Metadata to create `dplyr` summaries of your tagged animals.
~~~
# summary of animals you've tagged

proj58_tag_summary <- proj58_tag %>% 
  mutate(UTC_RELEASE_DATE_TIME = ymd_hms(UTC_RELEASE_DATE_TIME)) %>% 
  #filter(UTC_RELEASE_DATE_TIME > '2016-06-01') %>% #select timeframe, specific animals etc.
  group_by(year = year(UTC_RELEASE_DATE_TIME), COMMON_NAME_E) %>% 
  summarize(count = n(), 
            Meanlength = mean(`LENGTH (m)`, na.rm=TRUE), 
            minlength= min(`LENGTH (m)`, na.rm=TRUE), 
            maxlength = max(`LENGTH (m)`, na.rm=TRUE), 
            MeanWeight = mean(`WEIGHT (kg)`, na.rm = TRUE))

#view our summary table

proj58_tag_summary

~~~
{: .language-r}


### Detection Attributes

Lets add some biological context to our summaries! To do this we can join our Tag Metadata with our Matched Detections. To learn more about the different types of dataframe joins and how they function, see [here](https://hollyemblem.medium.com/joining-data-with-dplyr-in-r-874698eb8898).

~~~
# Average location of each animal, without release records

proj58_matched_full_no_release %>% 
  group_by(catalognumber) %>% 
  summarize(NumberOfStations = n_distinct(station),
            AvgLat = mean(latitude),
            AvgLong =mean(longitude))
~~~
{: .language-r}

Now lets try to join our metadata and detection extracts.
~~~
#First we need to make a tagname column in the tag metadata (to match the Detection Extract), and figure out the enddate of the tag battery.

proj58_tag <- proj58_tag %>% 
  mutate(enddatetime = (ymd_hms(UTC_RELEASE_DATE_TIME) + days(EST_TAG_LIFE))) %>% #adding enddate
  mutate(tagname = paste(TAG_CODE_SPACE,TAG_ID_CODE, sep = '-')) #adding tagname column

#Now we join by tagname, to the detection dataset (without the release information)

tag_joined_dets <- left_join(x = proj58_matched_full_no_release, y = proj58_tag, by = "tagname") #join!

#make sure any redeployed tags have matched within their deployment period only

tag_joined_dets <- tag_joined_dets %>% 
  filter(datecollected >= UTC_RELEASE_DATE_TIME & datecollected <= enddatetime)

View(tag_joined_dets)
~~~
{: .language-r}

Lets use this new joined dataframe to make summaries!
~~~
#Avg length per location

proj58_tag_det_summary <- tag_joined_dets %>% 
  group_by(detectedby, station, latitude, longitude)  %>%  
  summarise(AvgSize = mean(`LENGTH (m)`, na.rm=TRUE))

proj58_tag_det_summary

#export our summary table as CSV
write_csv(proj58_tag_det_summary, "detections_summary.csv", col_names = TRUE)

# count detections per transmitter, per array

proj58_matched_full_no_release %>% 
  group_by(catalognumber, station, detectedby, commonname) %>% 
  summarize(count = n()) %>% 
  select(catalognumber, commonname, detectedby, station, count)

# list all receivers each fish was seen on, and a number_of_receivers column too

receivers <- proj58_matched_full_no_release %>% 
  group_by(catalognumber) %>% 
  mutate(stations = (list(unique(station)))) %>% #create a column with a list of the stations
  dplyr::select(catalognumber, stations)  %>% #remove excess columns
  distinct_all() %>% #keep only one record of each
  mutate(number_of_stations = sapply(stations, length)) %>% #sapply: applies a function across a List - in this case we are applying length()
  as.data.frame()  

View(receivers)

# number of stations visited, start and end dates, and track length

animal_id_summary <- proj58_matched_full_no_release %>% 
  group_by(catalognumber) %>%
  summarise(dets = length(catalognumber),
            stations = length(unique(station)),
            min = min(datecollected), 
            max = max(datecollected), 
            tracklength = max(datecollected)-min(datecollected))

View(animal_id_summary)
~~~
{: .language-r}

### Summary of Detection Counts

Lets make an informative plot showing number of matched detections, per year and month.

~~~
proj58_matched_full_no_release  %>% 
  mutate(datecollected=ymd_hms(datecollected)) %>% #make datetime
  mutate(year_month = floor_date(datecollected, "months")) %>% #round to month
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
  ggtitle('Project 58 Detections by Month (2016-2017)')+ #title
  labs(fill = "Year") #legend title

~~~
{: .language-r}

### Other Example Plots

Some examples of complex plotting options. The most useful of these may include abacus plotting (an example with 'animal' and 'station' on the y-axis) as well as an example using `ggmap` and `geom_path` to create an example map showing animal movement.

~~~

#Use the color scales in this package to make plots that are pretty, 
#better represent your data, easier to read by those with colorblindness, and print well in grey scale.
library(viridis)

# an easy abacus plot!

abacus_animals <- 
  ggplot(data = proj58_matched_full, aes(x = datecollected, y = catalognumber, col = detectedby)) +
  geom_point() +
  ggtitle("Detections by animal") +
  theme(plot.title = element_text(face = "bold", hjust = 0.5)) +
  scale_color_viridis(discrete = TRUE)

abacus_animals

abacus_stations <- 
  ggplot(data = proj58_matched_full,  aes(x = datecollected, y = detectedby, col = catalognumber)) +
  geom_point() +
  ggtitle("Detections by Array") +
  theme(plot.title = element_text(face = "bold", hjust = 0.5)) +
  scale_color_viridis(discrete = TRUE)

abacus_stations #might be better with just a subset, huh??

# track movement using geom_path!!

proj58_subset <- proj58_matched_full %>%
  dplyr::filter(catalognumber %in% c('PROJ58-1191602-2014-07-24', 'PROJ58-1191606-2014-07-24', 
                               'PROJ58-1191612-2014-08-21', 'PROJ58-1218518-2015-09-16'))

View(proj58_subset)

movMap <- 
  ggmap(base, extent = 'panel') + #use the BASE we set up before
  ylab("Latitude") +
  xlab("Longitude") +
  geom_path(data = proj58_subset, aes(x = longitude, y = latitude, col = commonname)) + #connect the dots with lines
  geom_point(data = proj58_subset, aes(x = longitude, y = latitude, col = commonname)) + #layer the stations back on
  scale_colour_manual(values = c("red", "blue"), name = "Species")+ #
  facet_wrap(~catalognumber, nrow=2, ncol=2)+
  ggtitle("Inferred Animal Paths")

#to size the dots by number of detections you could do something like: size = (log(length(animal)id))?

movMap


# monthly latitudinal distribution of your animals (works best w >1 species)

proj58_matched_full %>%
  group_by(m=month(datecollected), catalognumber, scientificname) %>% #make our groups
  summarise(mean=mean(latitude)) %>% #mean lat
  ggplot(aes(m %>% factor, mean, colour=scientificname, fill=scientificname))+ #the data is supplied, but no info on how to show it!
  geom_point(size=3, position="jitter")+   # draw data as points, and use jitter to help see all points instead of superimposition
  #coord_flip()+   #flip x y, not needed here
  scale_colour_manual(values = "blue")+ #change the colour to represent the species better!
  scale_fill_manual(values = "grey")+ 
  geom_boxplot()+ #another layer
  geom_violin(colour="black") #and one more layer


#There are other ways to present a summary of data like this that we might have chosen. 
#geom_density2d() will give us a KDE for our data points and give us some contours across our chosen plot axes.

proj58_matched_full %>% 
  group_by(month=month(datecollected), catalognumber, scientificname) %>%
  summarise(meanlat=mean(latitude)) %>%
  ggplot(aes(month, meanlat, colour=scientificname, fill=scientificname))+
  geom_point(size=3, position="jitter")+
  scale_colour_manual(values = "blue")+
  scale_fill_manual(values = "grey")+
  geom_density2d(linewidth=7, lty=1) #this is the only difference from the plot above 

#anything you specify in the aes() is applied to the actual data points/whole plot, 
#anything specified in geom() is applied to that layer only (colour, size...)

# per-individual density contours - lots of plots: called facets!

proj58_matched_full %>%
  ggplot(aes(longitude, latitude))+
  facet_wrap(~catalognumber)+ #make one plot per individual
  geom_violin()
#Warnings going on above.
~~~
{: .language-r}

## FACT Node

### New data frames

To aid in the creating of useful Matched Detection summaries, we should create a new dataframe where we filter out release records from the detection extracts. This will leave only "true" detections.

~~~
#optional subsetted dataset to use: detections with releases filtered out!

tqcs_matched_10_11_no_release <- tqcs_matched_10_11 %>% 
  filter(receiver != "release")

#optional full dataset to use: detections with releases filtered out!

tqcs_matched_10_11_full_no_release <- tqcs_matched_10_11_full %>% 
  filter(receiver != "release")
~~~
{: .language-r}

### Mapping my Detections and Releases - static map

Where were my fish observed? We will make a static map of all the receiver stations where my fish was detected in two steps, using the package `ggmap`.

First, we set a basemap using the aesthetics and bounding box we desire. Next, we add the detection locations onto the basemap and look at our creation! 

~~~
base <- get_stadiamap(
  bbox = c(left = min(tqcs_matched_10_11$longitude),
           bottom = min(tqcs_matched_10_11$latitude), 
           right = max(tqcs_matched_10_11$longitude), 
           top = max(tqcs_matched_10_11$latitude)),
  maptype = "stamen_terrain_background", 
  crop = FALSE,
  zoom = 8)


#add your releases and detections onto your basemap

tqcs_map <- 
  ggmap(base, extent='panel') +
  ylab("Latitude") +
  xlab("Longitude") +
  geom_point(data = tqcs_matched_10_11, 
             aes(x = longitude,y = latitude), #specify the data
             colour = 'blue', shape = 19, size = 2) #lots of aesthetic options here!

#view your tagging map!

tqcs_map

~~~
{: .language-r}

### Mapping my Detections and Releases - interactive map

An interactive map can contain more information than a static map. Here we will explore the package `plotly` to create interactive "slippy" maps. These allow you to explore your map in different ways by clicking and scrolling through the output.

First, we will set our basemap's aesthetics and bounding box and assign this information (as a list) to a geo_styling variable. Then, we choose which detections we wish to use and identify the columns containing Latitude and Longitude, using the `plot_geo` function. Next, we use the `add_markers` function to write out what information we would like to have displayed when we hover our mouse over a station in our interactive map. In this case, we chose to use `paste` to join together the Station Name and its lat/long. Finally, we add all this information together, along with a title, using the `layout` function, and now we can explore our interactive map!

~~~
#set your basemap

geo_styling <- list(
  fitbounds = "locations", visible = TRUE, #fits the bounds to your data!
  showland = TRUE,
  landcolor = toRGB("gray95"),
  subunitcolor = toRGB("gray85"),
  countrycolor = toRGB("gray85")
)

#decide what data you're going to use

tqcs_map_plotly <- plot_geo(tqcs_matched_10_11, lat = ~latitude, lon = ~longitude) 

#add your markers for the interactive map

tqcs_map_plotly <- tqcs_map_plotly %>% add_markers(
  text = ~paste(catalognumber, scientificname, paste("Date detected:", datecollected), 
                paste("Latitude:", latitude), paste("Longitude",longitude), 
                paste("Detected by:", detectedby), paste("Station:", station), 
                paste("Contact:", contact_poc, contact_pi), sep = "<br />"),
  symbol = I("square"), size = I(8), hoverinfo = "text" 
)

#Add layout (title + geo stying)

tqcs_map_plotly <- tqcs_map_plotly %>% layout(
  title = 'TQCS Detections<br />(2010-2011)', geo = geo_styling
)

#View map

tqcs_map_plotly
~~~
{: .language-r}

### Summary of tagged animals

This section will use your Tagging Metadata to create `dplyr` summaries of your tagged animals.
~~~
# summary of animals you've tagged

tqcs_tag_summary <- tqcs_tag %>% 
  mutate(UTC_RELEASE_DATE_TIME = ymd_hms(UTC_RELEASE_DATE_TIME)) %>% 
  #filter(UTC_RELEASE_DATE_TIME > '2019-06-01') %>% #select timeframe, specific animals etc.
  group_by(year = year(UTC_RELEASE_DATE_TIME), COMMON_NAME_E) %>% 
 summarize(count = n(), 
            Meanlength = mean(LENGTH..m., na.rm=TRUE), 
            minlength= min(LENGTH..m., na.rm=TRUE), 
            maxlength = max(LENGTH..m., na.rm=TRUE), 
            MeanWeight = mean(WEIGHT..kg., na.rm = TRUE)) 
			
#view our summary table

tqcs_tag_summary

~~~
{: .language-r}


### Detection Attributes

Lets add some biological context to our summaries! To do this we can join our Tag Metadata with our Matched Detections. To learn more about the different types of dataframe joins and how they function, see [here](https://hollyemblem.medium.com/joining-data-with-dplyr-in-r-874698eb8898).

~~~
#Average location of each animal, without release records

tqcs_matched_10_11_no_release %>% 
  group_by(catalognumber) %>% 
  summarize(NumberOfStations = n_distinct(station),
            AvgLat = mean(latitude),
            AvgLong =mean(longitude))
~~~
{: .language-r}

Now lets try to join our metadata and detection extracts.
~~~
#First we need to make a tagname column in the tag metadata (to match the Detection Extract), and figure out the enddate of the tag battery.

tqcs_tag <- tqcs_tag %>% 
  mutate(enddatetime = (ymd_hms(UTC_RELEASE_DATE_TIME) + days(EST_TAG_LIFE))) %>% #adding enddate
  mutate(tagname = paste(TAG_CODE_SPACE,TAG_ID_CODE, sep = '-')) #adding tagname column

#Now we join by tagname, to the detections without the release information

tag_joined_dets <-  left_join(x = tqcs_matched_10_11_no_release, y = tqcs_tag, by = "tagname")

#make sure the redeployed tags have matched within their deployment period only

tag_joined_dets <- tag_joined_dets %>% 
  filter(datecollected >= UTC_RELEASE_DATE_TIME & datecollected <= enddatetime)

View(tag_joined_dets)
~~~
{: .language-r}

Lets use this new joined dataframe to make summaries!
~~~
# Avg length per location

tqcs_tag_det_summary <- tag_joined_dets %>% 
  group_by(detectedby, station, latitude, longitude)  %>%  
  summarise(AvgSize = mean(LENGTH..m., na.rm=TRUE))

tqcs_tag_det_summary

# count detections per transmitter, per array

tqcs_matched_10_11_no_release %>% 
  group_by(catalognumber, detectedby, commonname) %>% 
  summarize(count = n()) %>% 
  select(catalognumber, commonname, detectedby, count)

# list all receivers each fish was seen on, and a number_of_receivers column too

receivers <- tqcs_matched_10_11_no_release %>% 
  group_by(catalognumber) %>% 
  mutate(stations = (list(unique(station)))) %>% #create a column with a list of the stations
  dplyr::select(catalognumber, stations)  %>% #remove excess columns
  distinct_all() %>% #keep only one record of each
  mutate(number_of_stations = sapply(stations, length)) %>% #sapply: applies a function across a List - in this case we are applying length()
  as.data.frame() 

View(receivers)

animal_id_summary <- tqcs_matched_10_11_no_release %>% 
  group_by(catalognumber) %>%
  summarise(dets = length(catalognumber),
            stations = length(unique(station)),
            min = min(datecollected), 
            max = max(datecollected), 
            tracklength = max(datecollected)-min(datecollected))

View(animal_id_summary)


~~~
{: .language-r}

### Summary of Detection Counts

Lets make an informative plot showing number of matched detections, per year and month.

~~~
#try with tqcs_matched_10_11_full_no_release if you're feeling bold! takes ~30 secs

tqcs_matched_10_11_no_release  %>% 
  mutate(datecollected=ymd_hms(datecollected)) %>% #make datetime
  mutate(year_month = floor_date(datecollected, "months")) %>% #round to month
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
  ggtitle('TQCS Detections by Month (2010-2011)')+ #title
  labs(fill = "Year") #legend title

~~~
{: .language-r}

### Other Example Plots

Some examples of complex plotting options. The most useful of these may include abacus plotting (an example with 'animal' and 'station' on the y-axis) as well as an example using `ggmap` and `geom_path` to create an example map showing animal movement.
~~~
#Use the color scales in this package to make plots that are pretty, 
#better represent your data, easier to read by those with colorblindness, and print well in grey scale.
library(viridis)

# an easy abacus plot!

abacus_animals <- 
  ggplot(data = tqcs_matched_10_11_no_release, aes(x = datecollected, y = catalognumber, col = detectedby)) +
  geom_point() +
  ggtitle("Detections by animal") +
  theme(plot.title = element_text(face = "bold", hjust = 0.5)) +
  scale_color_viridis(discrete = TRUE)

abacus_animals

abacus_stations <- 
  ggplot(data = tqcs_matched_10_11_no_release,  aes(x = datecollected, y = station, col = catalognumber)) +
  geom_point() +
  ggtitle("Detections by station") +
  theme(plot.title = element_text(face = "bold", hjust = 0.5)) +
  scale_color_viridis(discrete = TRUE)

abacus_stations 

# track movement using geom_path!!

tqcs_subset <- tqcs_matched_10_11_no_release %>%
  dplyr::filter(catalognumber %in% 
                  c('TQCS-1049282-2008-02-28', 'TQCS-1049281-2008-02-28'))

View(tqcs_subset)

movMap <- 
  ggmap(base, extent = 'panel') + #use the BASE we set up before
  ylab("Latitude") +
  xlab("Longitude") +
  geom_path(data = tqcs_subset, aes(x = longitude, y = latitude, col = commonname)) + #connect the dots with lines
  geom_point(data = tqcs_subset, aes(x = longitude, y = latitude, col = commonname)) + #layer the stations back on
  scale_colour_manual(values = c("red", "blue"), name = "Species")+ #
  facet_wrap(~catalognumber)+
  ggtitle("Inferred Animal Paths")

#to size the dots by number of detections you could do something like: size = (log(length(animal)id))?

movMap

# monthly latitudinal distribution of your animals (works best w >1 species)

tqcs_matched_10_11 %>%
  group_by(m=month(datecollected), catalognumber, scientificname) %>% #make our groups
  summarise(mean=mean(latitude)) %>% #mean lat
  ggplot(aes(m %>% factor, mean, colour=scientificname, fill=scientificname))+ #the data is supplied, but no info on how to show it!
  geom_point(size=3, position="jitter")+   # draw data as points, and use jitter to help see all points instead of superimposition
  #coord_flip()+   #flip x y, not needed here
  scale_colour_manual(values = "blue")+ #change the colour to represent the species better!
  scale_fill_manual(values = "grey")+ 
  geom_boxplot()+ #another layer
  geom_violin(colour="black") #and one more layer


#There are other ways to present a summary of data like this that we might have chosen. 
#geom_density2d() will give us a KDE for our data points and give us some contours across our chosen plot axes.

tqcs_matched_10_11 %>% #doesnt work on the subsetted data, back to original dataset for this one
  group_by(month=month(datecollected), catalognumber, scientificname) %>%
  summarise(meanlat=mean(latitude)) %>%
  ggplot(aes(month, meanlat, colour=scientificname, fill=scientificname))+
  geom_point(size=3, position="jitter")+
  scale_colour_manual(values = "blue")+
  scale_fill_manual(values = "grey")+
  geom_density2d(linewidth=7, lty=1) #this is the only difference from the plot above 

#anything you specify in the aes() is applied to the actual data points/whole plot, 
#anything specified in geom() is applied to that layer only (colour, size...)

# per-individual density contours - lots of plots: called facets!
tqcs_matched_10_11 %>%
  ggplot(aes(longitude, latitude))+
  facet_wrap(~catalognumber)+ #make one plot per individual
  geom_violin()

~~~
{: .language-r}

## GLATOS Network

### Mapping my Detections and Releases - static map

Where were my fish observed? We will make a static map of all the receiver stations where my fish was detected in two steps, using the package `ggmap`.

First, we set a basemap using the aesthetics and bounding box we desire. Next, we add the detection locations onto the basemap and look at our creation! 

~~~
base <- get_stadiamap(
  bbox = c(left = min(all_dets$deploy_long),
           bottom = min(all_dets$deploy_lat), 
           right = max(all_dets$deploy_long), 
           top = max(all_dets$deploy_lat)),
  maptype = "stamen_terrain_background", 
  crop = FALSE,
  zoom = 8)


#add your detections onto your basemap
detections_map <- 
  ggmap(base, extent='panel') +
  ylab("Latitude") +
  xlab("Longitude") +
  geom_point(data = all_dets,
             aes(x = deploy_long,y = deploy_lat, colour = common_name_e), #specify the data
             shape = 19, size = 2) #lots of aesthetic options here!

#view your detections map!
detections_map

~~~
{: .language-r}

### Mapping my Detections and Releases - interactive map

An interactive map can contain more information than a static map. Here we will explore the package `plotly` to create interactive "slippy" maps. These allow you to explore your map in different ways by clicking and scrolling through the output.

First, we will set our basemap's aesthetics and bounding box and assign this information (as a list) to a geo_styling variable. Then, we choose which detections we wish to use and identify the columns containing Latitude and Longitude, using the `plot_geo` function. Next, we use the `add_markers` function to write out what information we would like to have displayed when we hover our mouse over a station in our interactive map. In this case, we chose to use `paste` to join together the Station Name and its lat/long. Finally, we add all this information together, along with a title, using the `layout` function, and now we can explore our interactive map!

~~~
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

#decide what data you're going to use

detections_map_plotly <- plot_geo(all_dets, lat = ~deploy_lat, lon = ~deploy_long) 

#add your markers for the interactive map

detections_map_plotly <- detections_map_plotly %>% add_markers(
  text = ~paste(animal_id, common_name_e, paste("Date detected:", detection_timestamp_utc), 
                paste("Latitude:", deploy_lat), paste("Longitude",deploy_long), 
                paste("Detected by:", glatos_array), paste("Station:", station), 
                paste("Project:",glatos_project_receiver), sep = "<br />"),
  symbol = I("square"), size = I(8), hoverinfo = "text" 
)
#Add layout (title + geo stying)

detections_map_plotly <- detections_map_plotly %>% layout(
  title = 'Lamprey and Walleye Detections<br />(2012-2013)', geo = geo_styling
)

#View map

detections_map_plotly
~~~
{: .language-r}

### Summary of tagged animals

This section will use your Tagging Metadata to create `dplyr` summaries of your tagged animals.
~~~
# summary of animals you've tagged
walleye_tag_summary <- walleye_tag %>% 
  mutate(GLATOS_RELEASE_DATE_TIME = ymd_hms(GLATOS_RELEASE_DATE_TIME)) %>% 
  #filter(GLATOS_RELEASE_DATE_TIME > '2012-06-01') %>% #select timeframe, specific animals etc.
  group_by(year = year(GLATOS_RELEASE_DATE_TIME), COMMON_NAME_E) %>% 
  summarize(count = n(), 
            Meanlength = mean(LENGTH, na.rm=TRUE), 
            minlength= min(LENGTH, na.rm=TRUE), 
            maxlength = max(LENGTH, na.rm=TRUE), 
            MeanWeight = mean(WEIGHT, na.rm = TRUE)) 
			

#view our summary table
walleye_tag_summary


~~~
{: .language-r}


### Detection Attributes

Lets add some biological context to our summaries! 

~~~
#Average location of each animal!

all_dets %>% 
  group_by(animal_id) %>% 
  summarize(NumberOfStations = n_distinct(station),
            AvgLat = mean(deploy_lat),
            AvgLong =mean(deploy_long))


# Avg length per location

all_dets_summary <- all_dets %>% 
  mutate(detection_timestamp_utc = ymd_hms(detection_timestamp_utc)) %>% 
  group_by(glatos_array, station, deploy_lat, deploy_long, common_name_e)  %>%  
  summarise(AvgSize = mean(length, na.rm=TRUE))

all_dets_summary

#export our summary table as CSV
write_csv(all_dets_summary, "detections_summary.csv", col_names = TRUE)

# count detections per transmitter, per array

all_dets %>% 
  group_by(animal_id, glatos_array, common_name_e) %>% 
  summarize(count = n()) %>% 
  select(animal_id, common_name_e, glatos_array, count)
  
# list all GLATOS arrays each fish was seen on, and a number_of_arrays column too

arrays <- all_dets %>% 
  group_by(animal_id) %>% 
  mutate(arrays =  (list(unique(glatos_array)))) %>% #create a column with a list of the arrays
  dplyr::select(animal_id, arrays)  %>% #remove excess columns
  distinct_all() %>% #keep only one record of each
  mutate(number_of_arrays = sapply(arrays,length)) %>% #sapply: applies a function across a List - in this case we are applying length()
  as.data.frame() 
  
View(arrays)
  
#Full summary of each animal's track
animal_id_summary <- all_dets %>% 
  group_by(animal_id) %>%
  summarise(dets = length(animal_id),
            stations = length(unique(station)),
            min = min(detection_timestamp_utc), 
            max = max(detection_timestamp_utc), 
            tracklength = max(detection_timestamp_utc)-min(detection_timestamp_utc))

View(animal_id_summary)

~~~
{: .language-r}

### Summary of Detection Counts

Lets make an informative plot showing number of matched detections, per year and month.

~~~
all_dets  %>% 
  mutate(detection_timestamp_utc=ymd_hms(detection_timestamp_utc)) %>% #make datetime
  mutate(year_month = floor_date(detection_timestamp_utc, "months")) %>% #round to month
 filter(common_name_e == 'walleye') %>% #can filter for specific stations, dates etc. doesn't have to be species!
  group_by(year_month) %>% #can group by station, species et - doesn't have to be by date
  summarize(count =n()) %>% #how many dets per year_month
  ggplot(aes(x = (month(year_month) %>% as.factor()), 
             y = count, 
             fill = (year(year_month) %>% as.factor())
  )
  )+ 
  geom_bar(stat = "identity", position = "dodge2")+ 
  xlab("Month")+
  ylab("Total Detection Count")+
  ggtitle('Walleye Detections by Month (2012-2013)')+ #title
  labs(fill = "Year") #legend title

~~~
{: .language-r}

### Other Example Plots

Some examples of complex plotting options. The most useful of these may include abacus plotting (an example with 'animal' and 'station' on the y-axis) as well as an example using `ggmap` and `geom_path` to create an example map showing animal movement.
~~~
# an easy abacus plot!

#Use the color scales in this package to make plots that are pretty, 
#better represent your data, easier to read by those with colorblindness, and print well in grey scale.
library(viridis)

abacus_animals <- 
  ggplot(data = all_dets, aes(x = detection_timestamp_utc, y = animal_id, col = glatos_array)) +
  geom_point() +
  ggtitle("Detections by animal") +
  theme(plot.title = element_text(face = "bold", hjust = 0.5)) +
  scale_color_viridis(discrete = TRUE)

abacus_animals

#another way to vizualize

abacus_stations <- 
  ggplot(data = all_dets,  aes(x = detection_timestamp_utc, y = station, col = animal_id)) +
  geom_point() +
  ggtitle("Detections by station") +
  theme(plot.title = element_text(face = "bold", hjust = 0.5)) +
  scale_color_viridis(discrete = TRUE)

abacus_stations

#track movement using geom_path!

movMap <- 
  ggmap(base, extent = 'panel') + #use the BASE we set up before
  ylab("Latitude") +
  xlab("Longitude") +
  geom_path(data = all_dets, aes(x = deploy_long, y = deploy_lat, col = common_name_e)) + #connect the dots with lines
  geom_point(data = all_dets, aes(x = deploy_long, y = deploy_lat, col = common_name_e)) + #layer the stations back on
  scale_colour_manual(values = c("red", "blue"), name = "Species")+ #
  facet_wrap(~animal_id, ncol = 6, nrow=1)+
  ggtitle("Inferred Animal Paths")


movMap


# monthly latitudinal distribution of your animals (works best w >1 species)

all_dets %>%
  group_by(month=month(detection_timestamp_utc), animal_id, common_name_e) %>% #make our groups
  summarise(meanlat=mean(deploy_lat)) %>% #mean lat
  ggplot(aes(month %>% factor, meanlat, colour=common_name_e, fill=common_name_e))+ #the data is supplied, but no info on how to show it!
  geom_point(size=3, position="jitter")+   # draw data as points, and use jitter to help see all points instead of superimposition
  #coord_flip()+   #flip x y, not needed here
  scale_colour_manual(values = c("brown", "green"))+ #change the colour to represent the species better!
  scale_fill_manual(values = c("brown", "green"))+  #colour of the boxplot
  geom_boxplot()+ #another layer
  geom_violin(colour="black") #and one more layer


# per-individual contours - lots of plots: called facets!
all_dets %>%
  ggplot(aes(deploy_long, deploy_lat))+
  facet_wrap(~animal_id)+ #make one plot per individual
  geom_violin()

~~~
{: .language-r}

## MigraMar Node

### New dataframes

To aid in the creating of useful Matched Detection summaries, we should create a new dataframe where we filter out release records from the detection extracts. This will leave only "true" detections.

~~~
#optional dataset to use: detections with releases filtered out!

gmr_matched_18_19_no_release <- gmr_matched_18_19  %>% 
  dplyr::filter(receiver != "release")
~~~
{: .language-r}


### Mapping my Detections and Releases - static map

Where were my fish observed? We will make a static map of all the receiver stations where my fish was detected in two steps, using the package `ggmap`.

First, we set a basemap using the aesthetics and bounding box we desire. Next, we add the detection locations onto the basemap and look at our creation! 

~~~
base <- get_stadiamap(
  bbox = c(left = min(gmr_matched_18_19_no_release$longitude),
           bottom = min(gmr_matched_18_19_no_release$latitude), 
           right = max(gmr_matched_18_19_no_release$longitude), 
           top = max(gmr_matched_18_19_no_release$latitude)),
  maptype = "stamen_terrain", 
  crop = FALSE,
  zoom = 12)


#add your releases and detections onto your basemap

gmr_tag_map <- 
  ggmap(base, extent='panel') +
  ylab("Latitude") +
  xlab("Longitude") +
  geom_point(data = gmr_matched_18_19_no_release, 
             aes(x = longitude,y = latitude), #specify the data
             colour = 'blue', shape = 19, size = 2) #lots of aesthetic options here!

#view your tagging map!

gmr_tag_map

~~~
{: .language-r}

### Mapping my Detections and Releases - interactive map

An interactive map can contain more information than a static map. Here we will explore the package `plotly` to create interactive "slippy" maps. These allow you to explore your map in different ways by clicking and scrolling through the output.

First, we will set our basemap's aesthetics and bounding box and assign this information (as a list) to a geo_styling variable. Then, we choose which detections we wish to use and identify the columns containing Latitude and Longitude, using the `plot_geo` function. Next, we use the `add_markers` function to write out what information we would like to have displayed when we hover our mouse over a station in our interactive map. In this case, we chose to use `paste` to join together the Station Name and its lat/long. Finally, we add all this information together, along with a title, using the `layout` function, and now we can explore our interactive map!

~~~
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

#decide what data you're going to use

detections_map_plotly <- plot_geo(gmr_matched_18_19_no_release, lat = ~latitude, lon = ~longitude) 

#add your markers for the interactive map
detections_map_plotly <- detections_map_plotly %>% add_markers(
  text = ~paste(catalognumber, commonname, paste("Date detected:", datecollected), 
                paste("Latitude:", latitude), paste("Longitude",longitude), 
                paste("Detected by:", detectedby), paste("Station:", station), 
                paste("Project:",collectioncode), sep = "<br />"),
  symbol = I("square"), size = I(8), hoverinfo = "text" 
)

#Add layout (title + geo stying)

detections_map_plotly <- detections_map_plotly %>% layout(
  title = 'GMR Tagged Animal Detections', geo = geo_styling
)

#View map
detections_map_plotly
~~~
{: .language-r}

### Summary of tagged animals

This section will use your Tagging Metadata to create `dplyr` summaries of your tagged animals.
~~~
# summary of animals you've tagged

gmr_tag_summary <- gmr_tag %>% 
  mutate(UTC_RELEASE_DATE_TIME = ymd_hms(UTC_RELEASE_DATE_TIME)) %>% 
  #dplyr::filter(UTC_RELEASE_DATE_TIME > '2018-06-01') %>% #select timeframe, specific animals etc.
  group_by(year = year(UTC_RELEASE_DATE_TIME), COMMON_NAME_E) %>% 
  summarize(count = n(), 
            Meanlength = mean(`LENGTH (m)`, na.rm=TRUE), 
            minlength= min(`LENGTH (m)`, na.rm=TRUE), 
            maxlength = max(`LENGTH (m)`, na.rm=TRUE), 
            MeanWeight = mean(`WEIGHT (kg)`, na.rm = TRUE)) 

# there are some species which don't have enough data to calculate a Min/Max value - these show `INF` instead in these fields.
#view our summary table

gmr_tag_summary
~~~
{: .language-r}


### Detection Attributes

Lets add some biological context to our summaries! To do this we can join our Tag Metadata with our Matched Detections. To learn more about the different types of dataframe joins and how they function, see [here](https://hollyemblem.medium.com/joining-data-with-dplyr-in-r-874698eb8898).

~~~
# Average location of each animal, without release records

gmr_matched_18_19_no_release %>% 
  group_by(catalognumber) %>% 
  summarize(NumberOfStations = n_distinct(station),
            AvgLat = mean(latitude),
            AvgLong =mean(longitude))
~~~
{: .language-r}

Now lets try to join our metadata and detection extracts.
~~~
#First we need to make a tagname column in the tag metadata (to match the Detection Extract), and figure out the enddate of the tag battery.

gmr_tag <- gmr_tag %>% 
  mutate(enddatetime = (ymd_hms(UTC_RELEASE_DATE_TIME) + days(EST_TAG_LIFE))) %>% #adding enddate
  mutate(tagname = paste(TAG_CODE_SPACE,TAG_ID_CODE, sep = '-')) #adding tagname column

#Now we join by tagname, to the detection dataset (without the release information)

tag_joined_dets <- left_join(x = gmr_matched_18_19_no_release, y = gmr_tag, by = "tagname") #join!

#make sure any redeployed tags have matched within their deployment period only

tag_joined_dets <- tag_joined_dets %>% 
  dplyr::filter(datecollected >= UTC_RELEASE_DATE_TIME & datecollected <= enddatetime)

View(tag_joined_dets)
~~~
{: .language-r}

Lets use this new joined dataframe to make summaries!
~~~
#Avg length per location

gmr_tag_det_summary <- tag_joined_dets %>% 
  group_by(commonname, detectedby, station, latitude, longitude)  %>%  
  summarise(AvgSize = mean(`LENGTH (m)`, na.rm=TRUE))

gmr_tag_det_summary

#export our summary table as CSV
write_csv(gmr_tag_det_summary, "detections_summary.csv", col_names = TRUE)

# count detections per transmitter, per array

gmr_matched_18_19_no_release %>% 
  group_by(catalognumber, station, detectedby, commonname) %>% 
  summarize(count = n()) %>% 
  dplyr::select(catalognumber, commonname, detectedby, station, count)

# list all receivers each fish was seen on, and a number_of_receivers column too

receivers <- gmr_matched_18_19_no_release %>% 
  group_by(catalognumber) %>% 
  mutate(stations = (list(unique(station)))) %>% #create a column with a list of the stations
  dplyr::select(catalognumber, stations)  %>% #remove excess columns
  distinct_all() %>% #keep only one record of each
  mutate(number_of_stations = sapply(stations, length)) %>% #sapply: applies a function across a List - in this case we are applying length()
  as.data.frame()  

View(receivers)

# number of stations visited, start and end dates, and track length

animal_id_summary <- gmr_matched_18_19_no_release %>% 
  group_by(catalognumber) %>%
  summarise(dets = length(catalognumber),
            stations = length(unique(station)),
            min = min(datecollected), 
            max = max(datecollected), 
            tracklength = max(datecollected)-min(datecollected))

view(animal_id_summary)
~~~
{: .language-r}

### Summary of Detection Counts

Lets make an informative plot showing number of matched detections, per year and month.

~~~
gmr_matched_18_19_no_release  %>% 
  mutate(datecollected=ymd_hms(datecollected)) %>% #make datetime
  mutate(year_month = floor_date(datecollected, "months")) %>% #round to month
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
  ggtitle('GMR Tagged Animal Detections by Month (2018-2019)')+ #title
  labs(fill = "Year") #legend title

~~~
{: .language-r}

### Other Example Plots

Some examples of complex plotting options. The most useful of these may include abacus plotting (an example with 'animal' and 'station' on the y-axis) as well as an example using `ggmap` and `geom_path` to create an example map showing animal movement.

~~~

#Use the color scales in this package to make plots that are pretty, 
#better represent your data, easier to read by those with colorblindness, and print well in grey scale.
library(viridis)

# an easy abacus plot!

abacus_animals <- 
  ggplot(data = gmr_matched_18_19_no_release, aes(x = datecollected, y = catalognumber, col = station)) +
  geom_point() +
  ggtitle("Detections by animal") +
  theme(plot.title = element_text(face = "bold", hjust = 0.5)) +
  scale_color_viridis(discrete = TRUE)

abacus_animals

abacus_stations <- 
  ggplot(data = gmr_matched_18_19_no_release,  aes(x = datecollected, y = station, col = catalognumber)) +
  geom_point() +
  ggtitle("Detections by Array") +
  theme(plot.title = element_text(face = "bold", hjust = 0.5)) +
  scale_color_viridis(discrete = TRUE)

abacus_stations 

# track movement using geom_path!!

movMap <- 
  ggmap(base, extent = 'panel') + #use the BASE we set up before
  ylab("Latitude") +
  xlab("Longitude") +
  geom_path(data = gmr_matched_18_19_no_release, aes(x = longitude, y = latitude, col = commonname)) + #connect the dots with lines
  geom_point(data = gmr_matched_18_19_no_release, aes(x = longitude, y = latitude, col = commonname)) + #layer the stations back on
  scale_colour_manual(values = c("red", "blue"), name = "Species")+ #
  facet_wrap(~catalognumber)+
  ggtitle("Inferred Animal Paths")

#to size the dots by number of detections you could do something like: size = (log(length(animal)id))?

movMap


# monthly latitudinal distribution of your animals (works best w >1 species)
gmr_matched_18_19_no_release %>%
  group_by(month=month(datecollected), catalognumber, scientificname) %>% #make our groups
  summarise(meanLat=mean(latitude)) %>% #mean lat
  ggplot(aes(month %>% factor, meanLat, colour=scientificname, fill=scientificname))+ #the data is supplied, but no info on how to show it!
  geom_point(size=3, alpha = 0.5, position = "jitter")+   # draw data as points, and use jitter to help see all points instead of superimposition
  geom_boxplot()

#anything you specify in the aes() is applied to the actual data points/whole plot, 
#anything specified in geom() is applied to that layer only (colour, size...)

# per-individual density contours - lots of plots: called facets!

gmr_matched_18_19_no_release %>%
  ggplot(aes(longitude, latitude))+
  facet_wrap(~catalognumber)+ #make one plot per individual
  geom_violin()
~~~
{: .language-r}

## OTN Node

### New dataframes

To aid in the creating of useful Matched Detection summaries, we should create a new dataframe where we filter out release records from the detection extracts. This will leave only "true" detections.

~~~
#optional dataset to use: detections with releases filtered out!

nsbs_matched_full_no_release <- nsbs_matched_full  %>% 
  filter(receiver != "release")
~~~
{: .language-r}


### Mapping my Detections and Releases - static map

Where were my fish observed? We will make a static map of all the receiver stations where my fish was detected in two steps, using the package `ggmap`.

First, we set a basemap using the aesthetics and bounding box we desire. Next, we add the detection locations onto the basemap and look at our creation! 

~~~
base <- get_stadiamap(
  bbox = c(left = min(nsbs_matched_full_no_release$longitude),
           bottom = min(nsbs_matched_full_no_release$latitude), 
           right = max(nsbs_matched_full_no_release$longitude), 
           top = max(nsbs_matched_full_no_release$latitude)),
  maptype = "stamen_toner_lite", 
  crop = FALSE,
  zoom = 5)


#add your releases and detections onto your basemap

nsbs_map <- 
  ggmap(base, extent='panel') +
  ylab("Latitude") +
  xlab("Longitude") +
  geom_point(data = nsbs_matched_full_no_release, 
             aes(x = longitude,y = latitude), #specify the data
             colour = 'blue', shape = 19, size = 2) #lots of aesthetic options here!

#view your tagging map!

nsbs_map

~~~
{: .language-r}

### Mapping my Detections and Releases - interactive map

An interactive map can contain more information than a static map. Here we will explore the package `plotly` to create interactive "slippy" maps. These allow you to explore your map in different ways by clicking and scrolling through the output.

First, we will set our basemap's aesthetics and bounding box and assign this information (as a list) to a geo_styling variable. Then, we choose which detections we wish to use and identify the columns containing Latitude and Longitude, using the `plot_geo` function. Next, we use the `add_markers` function to write out what information we would like to have displayed when we hover our mouse over a station in our interactive map. In this case, we chose to use `paste` to join together the Station Name and its lat/long. Finally, we add all this information together, along with a title, using the `layout` function, and now we can explore our interactive map!

~~~
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

#decide what data you're going to use

detections_map_plotly <- plot_geo(nsbs_matched_full_no_release, lat = ~latitude, lon = ~longitude) 

#add your markers for the interactive map
detections_map_plotly <- detections_map_plotly %>% add_markers(
  text = ~paste(catalognumber, commonname, paste("Date detected:", datecollected), 
                paste("Latitude:", latitude), paste("Longitude",longitude), 
                paste("Detected by:", detectedby), paste("Station:", station), 
                paste("Project:",collectioncode), sep = "<br />"),
  symbol = I("square"), size = I(8), hoverinfo = "text" 
)

#Add layout (title + geo stying)

detections_map_plotly <- detections_map_plotly %>% layout(
  title = 'NSBS Detections', geo = geo_styling
)

#View map
detections_map_plotly
~~~
{: .language-r}

### Summary of tagged animals

This section will use your Tagging Metadata to create `dplyr` summaries of your tagged animals.
~~~
# summary of animals you've tagged

nsbs_tag_summary <- nsbs_tag %>% 
  mutate(UTC_RELEASE_DATE_TIME = ymd_hms(UTC_RELEASE_DATE_TIME)) %>% 
  #filter(UTC_RELEASE_DATE_TIME > '2016-06-01') %>% #select timeframe, specific animals etc.
  group_by(year = year(UTC_RELEASE_DATE_TIME), COMMON_NAME_E) %>% 
  summarize(count = n(), 
            Meanlength = mean(`LENGTH (m)`, na.rm=TRUE), 
            minlength= min(`LENGTH (m)`, na.rm=TRUE), 
            maxlength = max(`LENGTH (m)`, na.rm=TRUE), 
            MeanWeight = mean(`WEIGHT (kg)`, na.rm = TRUE)) 

#view our summary table

View(nsbs_tag_summary)

~~~
{: .language-r}


### Detection Attributes

Lets add some biological context to our summaries! To do this we can join our Tag Metadata with our Matched Detections. To learn more about the different types of dataframe joins and how they function, see [here](https://hollyemblem.medium.com/joining-data-with-dplyr-in-r-874698eb8898).

~~~
# Average location of each animal, without release records

nsbs_matched_full_no_release %>% 
  group_by(catalognumber) %>% 
  summarize(NumberOfStations = n_distinct(station),
            AvgLat = mean(latitude),
            AvgLong =mean(longitude))
~~~
{: .language-r}

Now lets try to join our metadata and detection extracts.
~~~
#First we need to make a tagname column in the tag metadata (to match the Detection Extract), and figure out the enddate of the tag battery.

nsbs_tag <- nsbs_tag %>% 
  mutate(enddatetime = (ymd_hms(UTC_RELEASE_DATE_TIME) + days(EST_TAG_LIFE))) %>% #adding enddate
  mutate(tagname = paste(TAG_CODE_SPACE,TAG_ID_CODE, sep = '-')) #adding tagname column

#Now we join by tagname, to the detection dataset (without the release information)

tag_joined_dets <- left_join(x = nsbs_matched_full_no_release, y = nsbs_tag, by = "tagname") #join!

#make sure any redeployed tags have matched within their deployment period only

tag_joined_dets <- tag_joined_dets %>% 
  filter(datecollected >= UTC_RELEASE_DATE_TIME & datecollected <= enddatetime)

View(tag_joined_dets)
~~~
{: .language-r}

Lets use this new joined dataframe to make summaries!
~~~
#Avg length per location

nsbs_tag_det_summary <- tag_joined_dets %>% 
  group_by(detectedby, station, latitude, longitude)  %>%  
  summarise(AvgSize = mean(`LENGTH (m)`, na.rm=TRUE))

View(nsbs_tag_det_summary)

#export our summary table as CSV
write_csv(nsbs_tag_det_summary, "detections_summary.csv", col_names = TRUE)

# count detections per transmitter, per array

nsbs_matched_full_no_release %>% 
  group_by(catalognumber, station, detectedby, commonname) %>% 
  summarize(count = n()) %>% 
  dplyr::select(catalognumber, commonname, detectedby, station, count)

# list all receivers each fish was seen on, and a number_of_receivers column too

arrays <- nsbs_matched_full_no_release %>% 
  group_by(catalognumber) %>% 
  mutate(arrays = (list(unique(detectedby)))) %>% #create a column with a list of the stations
  dplyr::select(catalognumber, arrays)  %>% #remove excess columns
  distinct_all() %>% #keep only one record of each
  mutate(number_of_arrays = sapply(arrays, length)) %>% #sapply: applies a function across a List - in this case we are applying length()
  as.data.frame() 

View(arrays)

# number of stations visited, start and end dates, and track length

animal_id_summary <- nsbs_matched_full_no_release %>% 
  group_by(catalognumber) %>%
  summarise(dets = length(catalognumber),
            stations = length(unique(station)),
            min = min(datecollected), 
            max = max(datecollected), 
            tracklength = max(datecollected)-min(datecollected))

View(animal_id_summary)
~~~
{: .language-r}

### Summary of Detection Counts

Lets make an informative plot showing number of matched detections, per year and month.

~~~
nsbs_matched_full_no_release  %>% 
  mutate(datecollected=ymd_hms(datecollected)) %>% #make datetime
  mutate(year_month = floor_date(datecollected, "months")) %>% #round to month
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
  ggtitle('NSBS Detections by Month (2021-2022)')+ #title
  labs(fill = "Year") #legend title

~~~
{: .language-r}

### Other Example Plots

Some examples of complex plotting options. The most useful of these may include abacus plotting (an example with 'animal' and 'station' on the y-axis) as well as an example using `ggmap` and `geom_path` to create an example map showing animal movement.

~~~

#Use the color scales in this package to make plots that are pretty, 
#better represent your data, easier to read by those with colorblindness, and print well in grey scale.
library(viridis)

# an easy abacus plot!

abacus_animals <- 
  ggplot(data = nsbs_matched_full, aes(x = datecollected, y = catalognumber, col = detectedby)) +
  geom_point() +
  ggtitle("Detections by animal") +
  theme(plot.title = element_text(face = "bold", hjust = 0.5)) +
  scale_color_viridis(discrete = TRUE)

abacus_animals

abacus_arrays <- 
  ggplot(data = nsbs_matched_full,  aes(x = datecollected, y = detectedby, col = catalognumber)) +
  geom_point() +
  ggtitle("Detections by Array") +
  theme(plot.title = element_text(face = "bold", hjust = 0.5)) +
  scale_color_viridis(discrete = TRUE)

abacus_arrays #might be better with just a subset, huh??

# track movement using geom_path!!

nsbs_subset <- nsbs_matched_full %>%
  dplyr::filter(catalognumber %in% c('NSBS-Nessie', 'NSBS-1250981-2019-09-06', 
                                     'NSBS-1393342-2021-08-10', 'NSBS-1393332-2021-08-05'))

View(nsbs_subset)

movMap <- 
  ggmap(base, extent = 'panel') + #use the BASE we set up before
  ylab("Latitude") +
  xlab("Longitude") +
  geom_path(data = nsbs_subset, aes(x = longitude, y = latitude, col = commonname)) + #connect the dots with lines
  geom_point(data = nsbs_subset, aes(x = longitude, y = latitude, col = commonname)) + #layer the stations back on
  #scale_colour_manual(values = c("red", "blue"), name = "Species")+ #for more than one species
  facet_wrap(~catalognumber, nrow=2, ncol=2)+
  ggtitle("Inferred Animal Paths")

#to size the dots by number of detections you could do something like: size = (log(length(animal)id))?

movMap


# monthly latitudinal distribution of your animals (works best w >1 species)

nsbs_matched_full %>%
  group_by(m=month(datecollected), catalognumber, scientificname) %>% #make our groups
  summarise(mean=mean(latitude)) %>% #mean lat
  ggplot(aes(m %>% factor, mean, colour=scientificname, fill=scientificname))+ #the data is supplied, but no info on how to show it!
  geom_point(size=3, position="jitter")+   # draw data as points, and use jitter to help see all points instead of superimposition
  #coord_flip()+   #flip x y, not needed here
  scale_colour_manual(values = "blue")+ #change the colour to represent the species better!
  scale_fill_manual(values = "grey")+ 
  geom_boxplot()+ #another layer
  geom_violin(colour="black") #and one more layer


#There are other ways to present a summary of data like this that we might have chosen. 
#geom_density2d() will give us a KDE for our data points and give us some contours across our chosen plot axes.

nsbs_matched_full %>% 
  group_by(month=month(datecollected), catalognumber, scientificname) %>%
  summarise(meanlat=mean(latitude)) %>%
  ggplot(aes(month, meanlat, colour=scientificname, fill=scientificname))+
  geom_point(size=3, position="jitter")+
  scale_colour_manual(values = "blue")+
  scale_fill_manual(values = "grey")+
  geom_density2d(linewidth=7, lty=1) #this is the only difference from the plot above 

#anything you specify in the aes() is applied to the actual data points/whole plot, 
#anything specified in geom() is applied to that layer only (colour, size...)

# per-individual density contours - lots of plots: called facets!

nsbs_matched_full %>%
  ggplot(aes(longitude, latitude))+
  facet_wrap(~catalognumber)+ #make one plot per individual
  geom_violin()
#Warnings going on above.
~~~
{: .language-r}
