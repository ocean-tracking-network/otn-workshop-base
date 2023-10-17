---
title: Telemetry Reports for Array Operators
teaching: 30
exercises: 0
questions:
    - "How do I summarize and plot my deployments?"
    - "How do I summarize and plot my detections?"
---


### Mapping our stations - Static map

We can do the same exact thing with the deployment metadata from OUR project only!

~~~
names(hfx_deploy)

base <- get_stamenmap(
  bbox = c(left = min(hfx_deploy$DEPLOY_LONG), 
           bottom = min(hfx_deploy$DEPLOY_LAT), 
           right = max(hfx_deploy$DEPLOY_LONG), 
           top = max(hfx_deploy$DEPLOY_LAT)),
  maptype = "toner-lite", 
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
  filter(datecollected > '2021-06-01') %>% #select timeframe, stations etc.
  group_by(trackercode, station, tag_contact_pi, tag_contact_poc) %>% 
  summarize(count = n()) %>% 
  dplyr::select(trackercode, tag_contact_pi, tag_contact_poc, station, count)

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
  mutate(datecollected=ymd_hms(datecollected))  %>% 
  group_by(station, year = year(datecollected), month = month(datecollected)) %>% 
  summarize(count =n())

hfx_det_summary 

# Create a new data product, det_days, that give you the unique dates that an animal was seen by a station
stationsum <- hfx_qual_21_22_full %>% 
  group_by(station) %>%
  summarise(num_detections = length(datecollected),
            start = min(datecollected),
            end = max(datecollected),
            uniqueIDs = length(unique(fieldnumber)), 
            det_days=length(unique(as.Date(datecollected))))
View(stationsum)

~~~
{: .language-r}

### Plot of Detections 

Lets make an informative plot using `ggplot` showing the number of matched detections, per year and month. Remember: we can combine `dplyr` data manipulation and plotting into one step, using pipes!

~~~

hfx_qual_21_22_full %>%  
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
  ggtitle('HFX Animal Detections by Month')+ #title
  labs(fill = "Year") #legend title

~~~
{: .language-r}
