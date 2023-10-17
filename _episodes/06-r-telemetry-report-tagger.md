---
title: Telemetry Reports for Tag Owners
teaching: 30
exercises: 0
questions:
    - "How do I summarize and plot my detections?"
    - "How do I summarize and plot my tag metadata?"
---

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
base <- get_stamenmap(
  bbox = c(left = min(nsbs_matched_full_no_release$longitude),
           bottom = min(nsbs_matched_full_no_release$latitude), 
           right = max(nsbs_matched_full_no_release$longitude), 
           top = max(nsbs_matched_full_no_release$latitude)),
  maptype = "toner-lite", 
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
