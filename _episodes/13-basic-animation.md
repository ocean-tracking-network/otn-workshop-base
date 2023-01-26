---
title: "Basic Animation"
teaching: 20
exercises: 0
questions:
- "How do I set up my data extract for animation?"
- "How do I animate my animal movements?"
---

Static plots are excellent tools and are appropriate a lot of the time, but there are instances where something extra is needed to demonstrate your interesting fish movements: This is where plotting animated tracks can be a useful tool. In this lesson we will explore how to take data from your [OTN-style detection extract documents](https://members.oceantrack.org/data/otn-detection-extract-documentation-matched-to-animals) and animate the journey of one fish between stations.

### Getting our Packages

If not done already, we will first need to ensure we have all the required packages libraried in our R session.

~~~
library(glatos)
library(sf)
library(mapview)
library(plotly)
library(gganimate)
library(ggmap)
library(tidyverse)
~~~
{: .language-r}

### Preparing our Dataset

Before we can animate, we need to do some preprocessing on our dataset. For this animation we will be using `detection events` (a format we learned about in the `glatos` lessons) so we will need to first create that variable. To do this, we will read in our data using the `read_otn_detections` function from `glatos` and check for false detections with the `false_detections` function. 

For the purposes of this lesson we will assume that any detection that did not pass the filter is a false detection, and will filter them out using `filter(passed_filter != FALSE)`. It is important to note that for real data you will need to look over these detections to be sure they are truly false. 

Finally, we use the `detection_events` function with station as the `location_col` argument to get our detection events.

~~~
detection_events <- #create detections event variable
  read_otn_detections('proj58_matched_detections_2016.csv') %>% # reading detections
  false_detections(tf = 3600) %>%  #find false detections
  filter(passed_filter != FALSE) %>% 
  detection_events(location_col = 'station', time_sep=3600)
~~~
{: .language-r}

There is extra information in `detection_events` (such as the number of detections per event and the residence time in seconds) that can make some interesting plots, but for our visualization we only need the `animal_id, mean_longitude, mean_latitude, and first_detection` columns. So we will use the dplyr `select` function to create a dataframe with just those columns.

~~~
plot_data <- detection_events %>% 
  dplyr::select(animal_id, mean_longitude,mean_latitude, first_detection)
~~~
{: .language-r}

Additionally, animating many animal tracks can be compuationally intensive as well as create a potentially confusing plot, so for this lesson we will only be plotting one fish. We well subset our data by filtering where the `animal_id` is equal to `PROJ58-1218508-2015-10-13`.

~~~
one_fish <- plot_data[plot_data$animal_id == "PROJ58-1218508-2015-10-13",] 
~~~
{: .language-r}


### Preparing a Static Plot

Now that we have our data we can begin to create our plot. We will start with creating a static plot and then once happy with that, we will animate it.

The first thing we will do for our plot is download the basemap, this will be the background to our plot. To do this we will use the `get_stamenmap` function from `ggmap`. This function gets a Stamen Map based off a bounding box that we provide. To create the bounding box we will pass a vector of four values to the argument `bbox` ; those four values represent the left, bottom, right, and top boundaries of the map. 

To determine which values are needed we will use the `min` and `max` function on the `mean_longitude` and `mean_latitude` columns of our `one_fish` variable.  `min(one_fish$mean_longitude)` will be our left-most bound, `min(one_fish$mean_latitude)` will be our bottom bound, `max(one_fish$mean_longitude)` will be our right-most bound, and `max(one_fish$mean_latitude)` will be our top bound. This gives most of what we need for our basemap but we can further customize our plot with `maptype` which will change what type of map we use, `crop` which will crop raw map tiles to the specified bounding box, and `zoom` which will adjust the zoom level of the map.


#### A note on maptype
>  The different values you can put for maptype:
> "terrain", "terrain-background", "terrain-labels", "terrain-lines",
> "toner", "toner-2010", "toner-2011", "toner-background", "toner-hybrid",
> "toner-labels", "toner-lines", "toner-lite", "watercolor"
>
{: .tip}

~~~
basemap <- 
  get_stamenmap(
    bbox = c(left = min(one_fish$mean_longitude),
             bottom = min(one_fish$mean_latitude), 
             right = max(one_fish$mean_longitude), 
             top = max(one_fish$mean_latitude)),
    maptype = "toner-lite",
    crop = FALSE, 
    zoom = 8)

ggmap(basemap)
~~~
{: .language-r}

Now that we have our basemap ready we can create our static plot. We will store our plot in a variable called `act.plot` so we can access it later on. 

To start our plot we will call the `ggmap` function and pass it our basemap as an argument. To make our detection locations we will then call `geom_point`, supplying `one_fish` as the data argument and for the aesthetic will make the `x` argument equal to `mean_longitude` and the `y` argument will be `mean_latitude`.

We will then call `geom_path` to connect those detections supplying `one_fish` as the data argument and for the aesthetic `x` will again be  `mean_longitude` and `y` will be `mean_latitude`. 

Lastly, we will use the `labs` function to add context to our plot such as adding a `title`, a label for the `x` axis, and a label for the `y` axis. We are then ready to view our graph by calling `ggplotly` with `act.plot` as the argument!

~~~
act.plot <-
  ggmap(base) +
  geom_point(data = one_fish2, aes(x = mean_longitude, y = mean_latitude, group = animal_id, color = animal_id), size = 2) +
  geom_path(data = one_fish2, aes(x = mean_longitude, y = mean_latitude, group = animal_id, color = animal_id)) +
  labs(title = "ACT animation",
       x = "Longitude", y = "Latitude", color = "Tag ID")

ggplotly(act.plot)
~~~
{: .language-r}

### Animating our Static Plot

Once we have a static plot we are happy with we are ready for the final step of animating it! We will use the `gganimate` package for this, since it integrates nicely with `ggmap`.

To animate our plot we update our `act.plot` variable by using it as our base, then add a label for the dates to go along with the animation. We then call `transition_reveal`, which is a function from `gganimate` that determines how to create the transitions for the animations. There are many transitions you can use for animations with `gganimate` but `transition_reveal` will calculate intermediary values between time observations. For our plot we will pass `transition_reveal` the `first_detection` information. We will finally use the functions `shadow_mark` with the arguments of `past` equal to  `TRUE` and `future` equal to `FALSE`. This makes the animation continually show the previous data (a track) but not the future data yet to be seen (allowing it to be revealed as the animation progresses). 

Finally, to see our new animation we call the `animate` function with  `act.plot` as the argument.

~~~
act.plot <-
  act.plot +
  labs(subtitle = 'Date: {format(frame_along, "%d %b %Y")}') +
  transition_reveal(first_detection) +
  shadow_mark(past = TRUE, future = FALSE)

animate(act.plot)
~~~
{: .language-r}

