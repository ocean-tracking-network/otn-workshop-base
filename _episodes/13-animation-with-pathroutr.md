---
title: "Animation with pathroutr"
teaching: 20
exercises: 0
questions:
- "How can I create plots that avoid land?"

---

Our basic animations are great but you will soon run into issues where your plots are running over land, especially in more complex environments. To avoid this we need to use some land avoidance tool. For our next animation we will use the `pathroutr` library which you can find out more about at  https://jmlondon.github.io/pathroutr/. We will start out in much the same way we did for our basic animation lesson with getting our data ready but things will differ when we start to use `pathroutr` and some of the data we will need for it.


## Getting our data ready 

We will start out in the same way we did for the basic animation. We will use the same assumptions about the data this time and only look at one fish. We will also filter down the data and only look at 5 detection events due to the intensity of `pathroutr` and the calculations it runs.

~~~
library(glatos)
library(sf)
library(gganimate)
library(tidyverse)
library(pathroutr)
library(ggspatial)
library(sp)
library(raster)

detection_events <- #create detections event variable
  read_otn_detections('proj58_matched_detections_2016.csv') %>% # reading detections
  false_detections(tf = 3600) %>%  #find false detections
  filter(passed_filter != FALSE) %>% 
  detection_events(location_col = 'station', time_sep=3600)

plot_data <- detection_events %>% 
  dplyr::select(animal_id, mean_longitude,mean_latitude, first_detection)

one_fish <- plot_data[plot_data$animal_id == "PROJ58-1218518-2015-09-16",]

one_fish <- one_fish %>% filter(mean_latitude < 38.90 & mean_latitude > 38.87) %>% 
  slice(155:160)

~~~
{: .language-r}

## Getting our shapefile

The first big difference between our basic animation lesson and this one is that we will need to get a shapefile of the area where we are interested in to run the calculations for `pathroutr`. To do this we will use the `getData` function from the `raster` library which gets geographic data for anywhere in the world. The first argument we will pass to `getData` is the name of the dataset we want to use, for our visualization we will use `GADM`. When you use `GADM` with `getData` you need to provide a `country` argument, which is specified by a country's 3 letter ISO code. In our case we will pass `USA`. Last, we pass an argument for `level`, this is how much we would like the data to be subdivided. We are only interested in a portion of the country so we will pass `level` the value of `1` which means that the data will be divided by states. When we run this code we will get back a `SpatialPolygonsDataFrame` with the shapefiles for the US states.

~~~
USA<-getData('GADM', country='USA', level=1)
~~~
{: .language-r}

As we only need one state we will have to filter out the states we don't need. We can do this by filtering the data frame like we would a regular dataframe.

~~~
shape_file <- USA[USA$NAME_1 == 'Maryland',]
~~~
{: .language-r}

This shapefile is a great start but we want it to be a `sf` `multipolygon`. To do that we will run the `st_as_sf`` function on our shapefile. We also want to change the CRS to a projected coordinate system because we will be mapping this plot flat. To do that we will run `st_transform` and provide it the value `5070`.

~~~
md_polygon <- st_as_sf(single_poly) %>% st_transform(5070)
~~~
{: .language-r}

## Formatting our data

We will also need to make some changes to our detection data as well. To start we will need to turn the path of our fish into `SpatialPoints` for `pathroutr`. To do that we will get the `deploy_long` and `deploy_lat` with`dplyr::select` and add them to a variable called `path`. Using the `SpatialPoints` function we will pass our new  `path` variable  and `CRS("+proj=longlat +datum=WGS84 +no_defs")` for the `proj4string` argument. Like for our shapefile we will need to turn our path into an sf object by using the `st_as_sf` function and change the CRS to a projected coordinate system because we will be mapping it flat.

~~~
path <- one_fish %>%  dplyr::select(mean_longitude,mean_latitude)

path <- SpatialPoints(path, proj4string = CRS("+proj=longlat +datum=WGS84 +no_defs"))

path <-  st_as_sf(path)  %>% st_transform(5070)

~~~
{: .language-r}

We can do a quick plot to just check how things look and the moment and see if they are as expected.

~~~
ggplot() + 
  ggspatial::annotation_spatial(md_polygon, fill = "cornsilk3", size = 0) +
  geom_point(data = path, aes(x=unlist(map(geometry,1)), y=unlist(map(geometry,2)))) +
  geom_path(data = path, aes(x=unlist(map(geometry,1)), y=unlist(map(geometry,2))))  +
  theme_void()
~~~
{: .language-r}

## Using pathroutr

Now that we have everything we need we can begin to use `pathroutr`. First we will turn our path points into a `linestring` this way we can use `st_sample` to sample points on our path.

~~~
plot_path <- path %>% summarise(do_union = FALSE) %>% st_cast('LINESTRING')

track_pts <- st_sample(plot_path, size = 10000, type = "regular")
~~~
{: .language-r}

The  first `pathroutr` function we will use is `prt_visgraph`. This creates a visibility graph that connects all of the vertices for our shapefile with a Delaunay triangle mesh and removes any edges that cross land. You could think of this part as creating the viable paths an animal could move through.

~~~
vis_graph <- prt_visgraph(md_polygon, buffer = 150)
~~~
{: .language-r}

To reroute our path we will call the `prt_reroute` function. Passing `track_pts`, `md_polygon`, and `vis_graph` as arguments. To have a fully updated path we can run the prt_update_points passing our new path `track_pts_fix` with our old path `track_pts`.

~~~
track_pts_fix <- prt_reroute(track_pts, land_barrier, vis_graph, blend = TRUE)

track_pts_fix <- prt_update_points(track_pts_fix, track_pts)
~~~
{: .language-r}

Now with our newly fixed path we can visualize it and see how it looks. We can also use this plot as the base for our animation. For `geom_point` and `geom_path` we will pass in `track_pts_fix` for the `data` argument like most plots but we will need to get a little create for the  for the `x` and `y` arguments in aesthetic. `track_pts_fix` is a list of points so we will need a way to get just the `x` and 'y' values to supply them to the aesthetic. We will do this using `map(geometry,1)` to get a list of the values `unlist` to turn that into a vector.

~~~
pathroutrplot <- ggplot() + 
  ggspatial::annotation_spatial(md_polygon, fill = "cornsilk3", size = 0) +
  geom_point(data = track_pts_fix, aes(x=unlist(map(geometry,1)), y=unlist(map(geometry,2)))) +
  geom_path(data = track_pts_fix, aes(x=unlist(map(geometry,1)), y=unlist(map(geometry,2))))  +
  theme_void()

pathroutrplot
~~~
{: .language-r}

## Animating our new path

Now with our newly fixed path we can visualize it and see how it looks. We can also use this plot as the base for our animation. For `geom_point` and `geom_path` we will pass in `track_pts_fix` for the `data` argument like most plots but we will need to get a little creative for the `x` and `y` arguments in aesthetic. `track_pts_fix` is a list of points so we will need a way to get just the `x` and 'y' values to supply them to the aesthetic. We will do this using `map(geometry,1)` to get a list of the values and then the  `unlist` function to turn that list into a vector.

~~~
pathroutrplot <- ggplot() + 
  ggspatial::annotation_spatial(md_polygon, fill = "cornsilk3", size = 0) +
  geom_point(data = track_pts_fix, aes(x=unlist(map(geometry,1)), y=unlist(map(geometry,2)))) +
  geom_path(data = track_pts_fix, aes(x=unlist(map(geometry,1)), y=unlist(map(geometry,2))))  +
  theme_void()

pathroutrplot
~~~
{: .language-r}


With our plot in good order we are now able to animate. We will follow what we did in the basic animation lesson with overwriting our plot `pathroutrplot` variable by passing it `pathroutrplot` as the base. Call `transition_reveal` and then Fcall `shadow_mark` with the arguments of `past` equal to  `TRUE` and `future` equal to `FALSE`. Then we are good to call the `gganimate::animate` function and watch our creation.

~~~
pathroutrplot.animation <-
  pathroutrplot +
  transition_reveal(fid) +
  shadow_mark(past = TRUE, future = FALSE)

gganimate::animate(pathroutrplot.animation)
~~~
{: .language-r}