---
title: Telemetry Reports: Array Operators
teaching: 30
exercises: 0
questions:
      - "How do I summarize and plot my deployments?"
      - "How do I summarize and plot my detections?"
objectives:
      - "Learn to use dplyr, ggplot2, ggmap and plotly to make array summaries."
---


### Mapping my stations - Static map

Since we have already imported and joined our datasets, we can jump in. This section will use the Deployment metadata for your array.
~~~
library(ggmap)

#make a basemap for your stations, using the min/max deploy lat and longs as bounding box
base <- get_stamenmap(
  bbox = c(left = min(teq_deploy$DEPLOY_LONG), 
           bottom = min(teq_deploy$DEPLOY_LAT), 
           right = max(teq_deploy$DEPLOY_LONG), 
           top = max(teq_deploy$DEPLOY_LAT)),
  maptype = "terrain-background", 
  crop = FALSE,
  zoom = 8)

#filter for stations you want to plot
teq_deploy_plot <- teq_deploy %>% 
  mutate(deploy_date=ymd_hms(DEPLOY_DATE_TIME....yyyy.mm.ddThh.mm.ss.)) %>% #make a datetime
  mutate(recover_date=ymd_hms(RECOVER_DATE_TIME..yyyy.mm.ddThh.mm.ss.)) %>% #make a datetime
  filter(!is.na(deploy_date)) %>% #no null deploys
  filter(deploy_date > 2010-07-03) %>% #only looking at certain deployments!
  group_by(STATION_NO) %>% 
  summarise(MeanLat=mean(DEPLOY_LAT), MeanLong=mean(DEPLOY_LONG)) #get the mean location per station


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

An interactive map can contain more information than a static map.
 
~~~
library(plotly)

#set your basemap
geo_styling <- list(
  fitbounds = "locations", visible = TRUE, #fits the bounds to your data!
  showland = TRUE,
  landcolor = toRGB("gray95"),
  subunitcolor = toRGB("gray85"),
  countrycolor = toRGB("gray85")
)

#decide what data you're going to use
teq_map_plotly <- plot_geo(teq_deploy_plot, lat = ~MeanLat, lon = ~MeanLong)  

#add your markers for the interactive map
teq_map_plotly <- teq_map_plotly %>% add_markers(
  text = ~paste(STATION_NO, MeanLat, MeanLong, sep = "<br />"),
  symbol = I("square"), size = I(8), hoverinfo = "text" 
)

#Add layout (title + geo stying)
teq_map_plotly <- teq_map_plotly %>% layout(
  title = 'TEQ Deployments<br />(> 2010-07-03)', geo = geo_styling
)

#View map
teq_map_plotly
~~~
{: .language-r}

### Summary of Animals Detected.

Let's find out more about the animals detected by our array!
~~~
teq_qual_summary <- teq_qual_10_11 %>% 
  filter(datecollected > '2010-06-01') %>% #select timeframe, stations etc.
  group_by(trackercode, scientificname, tag_contact_pi, tag_contact_poc) %>% 
  summarize(count = n()) %>% 
  select(trackercode, tag_contact_pi, tag_contact_poc, scientificname, count)

#view our summary table
teq_qual_summary #remember, this is just the first 10,000 rows!

#export our summary table
write_csv(teq_qual_summary, "code/day1/teq_detection_summary_June2010_to_Dec2011.csv", col_names = TRUE)

~~~
{: .language-r}

### Summary of Detections
This can suggest array performance, hotspot stations, and be used as a metric for funders.
~~~
teq_det_summary  <- teq_qual_10_11  %>% 
  mutate(datecollected=ymd_hms(datecollected))  %>% 
  group_by(station, year = year(datecollected), month = month(datecollected)) %>% 
  summarize(count =n())

teq_det_summary #number of dets per month/year per station, remember: this is a subset!

~~~
{: .language-r}

### Plot of Detections
Lets make an informative plot showing number of matched detections, per year and month.
~~~
teq_qual_10_11 %>% #try with teq_qual_10_11_full if you're feeling bold! takes about 1 min to run on a fast machine
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
  ggtitle('TEQ Animal Detections by Month')+ #title
  labs(fill = "Year") #legend title

~~~
{: .language-r}

