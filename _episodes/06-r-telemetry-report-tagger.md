---
title: Telemetry Reports for Tag Owners
teaching: 30
exercises: 0
questions:
    - "How do I summarize and plot my detections?"
    - "How do I summarize and plot my tag metadata?"
---

### Mapping my Detections and Releases - static map

Where were my fish observed?

~~~
base <- get_stamenmap(
  bbox = c(left = min(proj58_matched_full$longitude),
           bottom = min(proj58_matched_full$latitude), 
           right = max(proj58_matched_full$longitude), 
           top = max(proj58_matched_full$latitude)),
  maptype = "terrain-background", 
  crop = FALSE,
  zoom = 8)


#add your releases and detections onto your basemap

proj58_map <- 
  ggmap(base, extent='panel') +
  ylab("Latitude") +
  xlab("Longitude") +
  geom_point(data = proj58_matched_full, 
             aes(x = longitude,y = latitude), #specify the data
             colour = 'blue', shape = 19, size = 2) #lots of aesthetic options here!

#view your tagging map!

proj58_map

~~~
{: .language-r}

### Mapping my Detections and Releases - interactive map

Let's use plotly!

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

detctions_map_plotly <- plot_geo(proj58_matched_full, lat = ~latitude, lon = ~longitude) 

#add your markers for the interactive map
detctions_map_plotly <- detctions_map_plotly %>% add_markers(
  text = ~paste(catalognumber, commonname, paste("Date detected:", datecollected), 
                paste("Latitude:", latitude), paste("Longitude",longitude), 
                paste("Detected by:", detectedby), paste("Station:", station), 
                paste("Project:",collectioncode)),
  symbol = I("square"), size = I(8), hoverinfo = "text" 
)

#Add layout (title + geo stying)

detctions_map_plotly <- detctions_map_plotly %>% layout(
  title = 'Project 58 Detections', geo = geo_styling
)

#View map
detctions_map_plotly
~~~
{: .language-r}

### Summary of tagged animals

This section will use your Tagging Metadata
~~~
# summary of animals you've tagged
normDate <- Vectorize(function(x) {
  if (!is.na(suppressWarnings(as.numeric(x))))  # Win excel
    as.Date(as.numeric(x), origin="1899-12-30")
  else
    as.Date(x, format="%y/%m/%d")
})

res <- as.Date(normDate(proj58_tag$UTC_RELEASE_DATE_TIME[0:52]), origin="1970-01-01")
# summary of animals you've tagged

full_dates = c(ymd_hms(res, truncated = 3), ymd_hms(proj58_tag$UTC_RELEASE_DATE_TIME[53:89]))
View(full_dates)

proj58_tag <- proj58_tag %>%
  mutate(UTC_RELEASE_DATE_TIME = full_dates)

proj58_tag_summary <- proj58_tag %>% 
  #mutate(UTC_RELEASE_DATE_TIME = full_dates) %>% 
  #filter(UTC_RELEASE_DATE_TIME > '2019-06-01') %>% #select timeframe, specific animals etc.
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

Lets add some biological context to our summaries!

~~~
#Average location of each animal, without release records

proj58_matched_full %>% 
  group_by(catalognumber) %>% 
  summarize(NumberOfStations = n_distinct(station),
            AvgLat = mean(latitude),
            AvgLong =mean(longitude))

#Lets try to join to our tag metadata to get some more context!!
#First we need to make a tagname column in the tag metadata, and figure out the enddate of the tag battery
proj58_tag <- proj58_tag %>% 
  mutate(enddatetime = (ymd_hms(UTC_RELEASE_DATE_TIME) + days(EST_TAG_LIFE))) %>% #adding enddate
  mutate(tagname = paste(TAG_CODE_SPACE,TAG_ID_CODE, sep = '-')) #adding tagname column

#Now we join by tagname, to the detections without the release information

tag_joined_dets <- left_join(x = proj58_matched_full, y = proj58_tag, by = "tagname")

#make sure the redeployed tags have matched within their deployment period only

tag_joined_dets <- tag_joined_dets %>% 
  filter(datecollected >= UTC_RELEASE_DATE_TIME & datecollected <= enddatetime)

View(tag_joined_dets)

#Lets use this new dataframe to make summaries! Avg length per location

proj58_tag_det_summary <- tag_joined_dets %>% 
  group_by(detectedby, station, latitude, longitude)  %>%  
  summarise(AvgSize = mean(`LENGTH (m)`, na.rm=TRUE))

proj58_tag_det_summary

#export our summary table as CSV
write_csv(proj58_tag_det_summary, "detections_summary.csv", col_names = TRUE)

# count detections per transmitter, per array

proj58_matched_full %>% 
  group_by(catalognumber, station, commonname) %>% 
  summarize(count = n()) %>% 
  select(catalognumber, commonname, station, count)

# list all receivers each fish was seen on, and a number_of_receivers column too

receivers <- proj58_matched_full %>% 
  group_by(catalognumber) %>% 
  mutate(receivers = (list(unique(station)))) %>% #create a column with a list of the stations
  dplyr::select(catalognumber, receivers)  %>% #remove excess columns
  distinct_all() %>% #keep only one record of each
  mutate(number_of_receivers = sapply(receivers,length)) %>% #sapply: applies a function across a List - in this case we are applying length()
  as.data.frame() 

View(receivers)
~~~
{: .language-r}

### Summary of Detection Counts

Lets make an informative plot showing number of matched detections, per year and month.

~~~
proj58_matched_full  %>% 
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
  ggtitle('Project 58 Detections by Month (2014-2017)')+ #title
  labs(fill = "Year") #legend title

~~~
{: .language-r}

### Other Example Plots

Some examples of complex plotting options
~~~
# an easy abacus plot!

#Use the color scales in this package to make plots that are pretty, 
#better represent your data, easier to read by those with colorblindness, and print well in grey scale.
library(viridis)

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

proj58_matched_full %>% #doesnt work on the subsetted data, back to original dataset for this one
  group_by(month=month(datecollected), catalognumber, scientificname) %>%
  summarise(meanlat=mean(latitude)) %>%
  ggplot(aes(month, meanlat, colour=scientificname, fill=scientificname))+
  geom_point(size=3, position="jitter")+
  scale_colour_manual(values = "blue")+
  scale_fill_manual(values = "grey")+
  geom_density2d(size=7, lty=1) #this is the only difference from the plot above 

#anything you specify in the aes() is applied to the actual data points/whole plot, 
#anything specified in geom() is applied to that layer only (colour, size...)

# per-individual density contours - lots of plots: called facets!
proj58_matched_full %>%
  ggplot(aes(longitude, latitude))+
  facet_wrap(~catalognumber)+ #make one plot per individual
  geom_violin()
#Warnings going on above.

View(proj58_matched_full)
abacus_animals <- 
  ggplot(data = proj58_matched_full, aes(x = datecollected, y = tagname, col = detectedby)) +
  geom_point() +
  ggtitle("Detections by animal") +
  theme(plot.title = element_text(face = "bold", hjust = 0.5)) +
  scale_color_viridis(discrete = TRUE)

abacus_animals

abacus_stations <- 
  ggplot(data = proj58_matched_full,  aes(x = datecollected, y = station, col = tagname)) +
  geom_point() +
  ggtitle("Detections by station") +
  theme(plot.title = element_text(face = "bold", hjust = 0.5)) +
  scale_color_viridis(discrete = TRUE)

abacus_stations #might be better with just a subet, huh??

#track movement using geom_path!!

#### Having trouble getting this working.
movMap <- 
  ggmap(base, extent = 'panel') + #use the BASE we set up before
  ylab("Latitude") +
  xlab("Longitude") +
  geom_path(data = proj58_matched_full, aes(x = longitude, y = latitude, col = commonname)) + #connect the dots with lines
  geom_point(data = proj58_matched_full, aes(x = longitude, y = latitude, col = commonname)) + #layer the stations back on
  scale_colour_manual(values = c("red", "blue"), name = "Species")+ #
  facet_wrap(~tagname, ncol = 6, nrow=1)+
  ggtitle("Inferred Animal Paths")

#to size the dots by number of detections you could do something like: size = (log(length(animal)id))?

movMap


# monthly latitudinal distribution of your animals (works best w >1 species)

proj58_matched_full %>%
  group_by(month=month(datecollected), tagname, commonname) %>% #make our groups
  summarise(meanlat=mean(latitude)) %>% #mean lat
  ggplot(aes(month %>% factor, meanlat, colour=commonname, fill=commonname))+ #the data is supplied, but no info on how to show it!
  geom_point(size=3, position="jitter")+   # draw data as points, and use jitter to help see all points instead of superimposition
  #coord_flip()+   #flip x y, not needed here
  scale_colour_manual(values = c("brown", "green"))+ #change the colour to represent the species better!
  scale_fill_manual(values = c("brown", "green"))+  #colour of the boxplot
  geom_boxplot()+ #another layer
  geom_violin(colour="black") #and one more layer


# per-individual contours - lots of plots: called facets!
proj58_matched_full %>%
  ggplot(aes(longitude, latitude))+
  facet_wrap(~tagname)+ #make one plot per individual
  geom_violin()

~~~
{: .language-r}


