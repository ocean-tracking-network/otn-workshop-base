---
title: Telemetry Reports: Tag Owners
teaching: 30
exercises: 0
questions:
      - "How do I summarize and plot my detections?"
objectives:
      - "Learn to use dplyr, ggplot2, ggmap and plotly to make tag summaries."
---

### Mapping my Detections and Releases - static map

~~~
base <- get_stamenmap(
  bbox = c(left = min(tqcs_matched_10_11$longitude),
           bottom = min(tqcs_matched_10_11$latitude), 
           right = max(tqcs_matched_10_11$longitude), 
           top = max(tqcs_matched_10_11$latitude)),
  maptype = "terrain-background", 
  crop = FALSE,
  zoom = 8)


#add your releases and detections onto your basemap
tqcs_map <- 
  ggmap(base, extent='panel') +
  ylab("Latitude") +
  xlab("Longitude") +
  geom_point(data = tqcs_matched_10_11, #filtering for recent deployments
             aes(x = longitude,y = latitude), #specify the data
             colour = 'blue', shape = 19, size = 2) #lots of aesthetic options here!

#view your tagging map!
tqcs_map

~~~
{: .language-r}

### Mapping my Detections and Releases - interactive map

Let's use plotly!

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

This section will use your Tagging Metadata
~~~
# summary of animals you've tagged
tqcs_tag_summary <- tqcs_tag %>% 
  mutate(UTC_RELEASE_DATE_TIME = ymd_hms(UTC_RELEASE_DATE_TIME)) %>% 
  #filter(UTC_RELEASE_DATE_TIME > '2019-06-01') %>% #select timeframe, specific animals etc.
  group_by(year = year(UTC_RELEASE_DATE_TIME), COMMON_NAME_E) %>% 
  summarize(count = n(), 
            Meanlength = mean(LENGTH..m., na.rm=TRUE), 
            minlength= min(LENGTH..m.), 
            maxlength = max(LENGTH..m.), 
            MeanWeight = mean(WEIGHT..kg., na.rm = TRUE)) 
			
#view our summary table
tqcs_tag_summary

~~~
{: .language-r}

Q: Since we don't have the ability to represent time, what are some optimal subsetting strategies for presenting data to `mapview()`?

### Detection attributes by year/month

????

~~~
??????
~~~
{: .language-r}

### Summary of Detection Counts

Lets make an informative plot showing number of matched detections, per year and month.

~~~
tqcs_matched_10_11  %>% #try with tqcs_matched_10_11_full if you're feeling bold! takes ~30 secs
  #TODO - filtered for no releases
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

Some examples of complex plotting options
~~~
# monthly latitudinal distribution of blue sharks (works best w >1 species)

tqcs_matched_10_11 %>%
  group_by(m=month(datecollected), catalognumber, scientificname) %>% #make our groups
  summarise(mean=mean(latitude)) %>% #mean lat
  ggplot(aes(m %>% factor, mean, colour=scientificname, fill=scientificname))+ #the data is supplied, but no info on how to show it!
  geom_point(size=3, position="jitter")+   # draw data as points, and use jitter to help see all points instead of superimposition
  #coord_flip()+   #flip x y, not needed here
  scale_colour_manual(values = "blue")+ #change the colour to represent the species better!
  scale_fill_manual(values = "grey")+ 
  geom_boxplot()+ #another layer
  geom_violin(colour="black") #aaaaaand another layer


#There are other ways to present a summary of data like this that we might have chosen. 
#geom_density2d() will give us a KDE for our data points and give us some contours across our chosen plot axes.

tqcs_matched_10_11 %>% #doesnt work on the subsetted data, back to original dataset for this one
  group_by(m=month(datecollected), catalognumber, scientificname) %>%
  summarise(mean=mean(latitude)) %>%
  ggplot(aes(m, mean, colour=scientificname, fill=scientificname))+
  geom_point(size=3, position="jitter")+
  scale_colour_manual(values = "blue")+
  scale_fill_manual(values = "grey")+
  geom_density2d(size=7, lty=1) #this is the only difference from the plot above 

#anything you specify in the aes() is applied to the actual data points/whole plot, 
#anything specified in geom() is applied to that layer only (colour, size...)

# per-individual density contours - lots of plots: called facets!
tqcs_matched_10_11 %>%
  ggplot(aes(latitude, longitude))+
  facet_wrap(~catalognumber)+ #make one plot per individual
  geom_violin()


~~~
{: .language-r}


