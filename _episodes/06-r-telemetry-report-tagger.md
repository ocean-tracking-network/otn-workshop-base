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
  bbox = c(left = min(all_dets$deploy_long),
           bottom = min(all_dets$deploy_lat), 
           right = max(all_dets$deploy_long), 
           top = max(all_dets$deploy_lat)),
  maptype = "terrain-background", 
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

detctions_map_plotly <- plot_geo(all_dets, lat = ~deploy_lat, lon = ~deploy_long) 

#add your markers for the interactive map

detctions_map_plotly <- detctions_map_plotly %>% add_markers(
  text = ~paste(animal_id, common_name_e, paste("Date detected:", detection_timestamp_utc), 
                paste("Latitude:", deploy_lat), paste("Longitude",deploy_long), 
                paste("Detected by:", glatos_array), paste("Station:", station), 
                paste("Project:",glatos_project_receiver)),
  symbol = I("square"), size = I(8), hoverinfo = "text" 
)
#Add layout (title + geo stying)

detctions_map_plotly <- detctions_map_plotly %>% layout(
  title = 'Lamprey and Walleye Detections<br />(2012-2013)', geo = geo_styling
)

#View map

detctions_map_plotly
~~~
{: .language-r}

### Summary of tagged animals

This section will use your Tagging Metadata
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
  group_by(transmitter_id, glatos_array, common_name_e) %>% 
  summarize(count = n()) %>% 
  select(transmitter_id, common_name_e, glatos_array, count)
  
# list all glatos arrays each fish was seen on, and a number_of_arrays column too

all_dets %>% 
  group_by(animal_id) %>% 
  mutate(arrays =  (list(unique(glatos_array)))) %>% #create a column with a list of the arrays
  dplyr::select(animal_id, arrays)  %>% #remove excess columns
  distinct_all() %>% #keep only one record of each
  mutate(number_of_arrays = sapply(arrays,length)) %>% #sapply: applies a function across a List - in this case we are applying length()
  as.data.frame() 

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

Some examples of complex plotting options
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


