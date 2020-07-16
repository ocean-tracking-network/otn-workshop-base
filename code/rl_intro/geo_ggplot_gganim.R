# Using dplyr and ggplot2 to view, clean and plot telemetry data #####
# with a bit of discussion about handling geospatial data #
# Curriculum built originally by Robert Lennox of NORCE, 
# first version of this module delivered as part of ideasOTN in February 2020.

# To verify your environment is ready to work along with this code, 
# try all of these imports and examine the output closely for errors.
# install.packages('name') for the packages that are missing.
# If you ran through the setup for this, you should be alright.

### Imports ====

# Tidyverse - provides dplyr, ggplot2, and many other packages that simplify data.frame manipulation in R
library(tidyverse)

# Marmap - library that allows non-straight-line interpolation between two points. 
# Useful for avoiding land masses when interpolating fish positions.
library(marmap)

# Lubridate - part of Tidyverse, improves the process of creating date objects 
library(lubridate)

# gganimate and gifski help you animate ggplot objects
library(gganimate)
library(gifski)

# R language Bindings for the GEOS library, a pre-compiled, open source geometry engine for fast spatial calculation
library(rgeos)
library(mapproj)

# Package for dealing with argos data, some useful functions for working with a series of geospatial data points
library(argosfilter) # we're mainly going to use its distance-calculator.

# spdplyr - use subsetting/selection syntax on spatial dataframes.
# mapview - generate a local webservice that shows you a map representation of your
# spatial dataframe.
library(spdplyr)
library(mapview)

# setwd() !====================================
# If you're following along, this is a great time to set your working directory!
# either navigate to this folder with the Files window in the lower right of RStudio ↴
# click "⚙More" and and hit Set as Working Directory
# or run the below command
# setwd("[/wherever/you/put/this]/code/rl_intro")

# If you were to instead read in a CSV file of your own detection data:
# seaTrout <- read.csv("my_data_folder/seaTrout.csv")

# For the purposes of following along today,
# you can also load this included .rda file of data.
# We can quickly peek at it again to make sure it's what we want.

load("seaTrout.rda")

glimpse(seaTrout)

# Note that it's the full 1.5 million entries, 
# not the subset we were using in the intro!


## Handling spatial objects in R ####

library(rgdal)
library(rgeos)

# we have coordinates in UTM, a metric based projection
# we want to work with latitude longitude, so we must convert

# Say that stS is a copy of our seaTrout data
stS<-seaTrout 

# note: both the sp and raster libraries can provide these functions
# Currently we're using sp brought in w/ rgeos

coordinates(stS)<-~lon+lat # tell stS that it's a spatial data frame with coordinates in lon and lat
proj4string(stS)<-CRS("+proj=utm +zone=33 +ellps=WGS84 +datum=WGS84 +units=m +no_defs") 

# Northern Norway is in reference system UTM 33
# http://www.dmap.co.uk/utmworld.htm is one of many lookups for UTM zone selection (NS is zone 20N)

# We'd like to project this into longlat - but spTransform can take this to any projection / coordinate reference system we need.
st<-spTransform(stS, CRS("+init=epsg:28992"))   # what is epsg:28992 - https://epsg.io/28992 - netherlands/dutch topographic map in easting/northing
st<-data.frame(st)  # results are still a SpatialPointsDataFrame, to go back to data.frame
View(st)  # It knows the coords should go in lon and lat columns, but they're actually easting/northing now as per the CRS.

st<-spTransform(stS, CRS("+proj=longlat +datum=WGS84")) # ok let's put it in lat/lon WGS84
st<-data.frame(st)
View(st)

# So now we have a spatially-aware data frame, using lat and lon as its coordinates in the appropriate CRS
# Now we want to see the underlying study area, 
# we can use the min/max of our lat lon to subset a world map 
# or to fetch a terrain/bathy map from NOAA using marmap

x=.5 # padding for our data's bounds
st<- st %>% as_tibble # put our data back into tibble form explicitly
bgo <- getNOAA.bathy(lon1 = min(st$lon-x), lon2 = max(st$lon+x),
                     lat1 = min(st$lat-x), lat2 = max(st$lat+x), resolution = 1) # higher resolutions are very big.

# Because there are some strange interplay between marmap and raster and rgdal on Windows,
# you may have to round down and up your boundary variables to whole numbers.
# Here's how to do that:

#bgo <- getNOAA.bathy(lon1 = floor(min(st$lon-x)), lon2 = ceiling(max(st$lon+x)),
#                       lat1 = floor(min(st$lat-x)), lat2 = ceiling(max(st$lat+x)),
#                       resolution = 1)

class(bgo); # check the data type of bgo
# what's a 'bathy' object?
View(bgo)   # can't View it...
bgo         # yikes!
dim(bgo)    # ok so it's a grid, 125 x 76, with -## values representing depths 

plot(bgo)   # it plots!
plot(bgo, col="royalblue")

autoplot(bgo)  # but ggplot2::autoplot() sees its type and knows more about it
               # e.g. understands what its scale ratio ought to be.

# Base ggplot wants to see tibbles that we can define in the aesthetic aes() function.
# How would we turn this bathy raster into a x,y,z data.frame for easy plotting and then into a tibble?
# we can use fortify.
?fortify
# This pipe chain works for any raster file! Turn it into (x,y,z) and optionally make it a tibble.
bgo %>% fortify %>% as_tibble   

# NB: This function's being deprecated someday. Being replaced by broom::tidy
# but broom doesn't know what a bathy object is yet. One day, this will be the pipe to use:
# library(broom)
# bgo %>% broom::tidy %>% as_tibble

# Let's really lay on the style with ggplot
bgo %>% 
  fortify %>% 
  ggplot(aes(x, y, fill=z))+
  geom_raster()   +  # raster-fy - plot to here first, see the values on a blue-scale. This isn't the fjords of Norway....
  scale_fill_etopo() +  # color in the pixels with marmap's scale_fill_etopo to see the positive values more clearly.
  labs(x="Longitude", y="Latitude", fill="Depth")+
  theme_classic()+
  theme(legend.position="top")+
  theme(legend.key.width = unit(5, "cm"))

## You can save the output of the plot chain to a variable instead of showing it.

bplot<-bgo %>%
  fortify %>%  # Turn a raster into a data.frame 
  ggplot(aes(x, y, z=z, fill=z))+  
  geom_raster()+       # raster-ify
  scale_fill_etopo()+  # color in the pixels
  labs(x="Longitude", y="Latitude", fill="Depth")+
  theme_classic()+
  theme(legend.position="top") +  # same plot as before up to here
  geom_point(data=st %>%   # now let's add our station locations to the plot!
               as_tibble() %>% 
               distinct(lon, lat), # only plot one point per lat,lon pair, not 1.5m points!
             aes(lon, lat), inherit.aes=F, pch=21, fill="red", size=2)+ # don't inherit aesthetics from the parent, 
                                                                        # original map is lat/lon/depth, points without Z vals will fail to plot!
  theme(legend.key.width = unit(5, "cm"))

bplot  # now the plot is saved in bplot, show it by running just the variable name.


####
## More tidy functions you may encounter in your workflow ####
####

# Filtering and data processing 

st<-as_tibble(st) # make sure st is a tibble again (speedier?)

# One pipe to fix dates, 
# filter subsets, 
# calculate lead and lag locations,
# summarize multiple consecutive detections at one station into one entry,
# and calculate new derived values, in this case, bearing and distance.



st_summary <- st %>%  # overwrites the dataframe we're working on with the result of this pipe!
  mutate(dt=ymd_hms(DateTime)) %>% 
  dplyr::select(-1, -2, -DateTime) %>%  # Don't return DateTime, or column 1 or 2 of the data
 # filter(month(dt)>5 & month(dt)<10) %>%  # filter for just a range of months?
  arrange(dt) %>% 
  group_by(tag.ID) %>% 
  mutate(llon=lag(lon), llat=lag(lat)) %>%  # lag longitude, lag latitude (previous position)
  filter(lon!=lag(lon)) %>%  # If you didn't change positions, drop this row.
  # rowwise() %>% 
  filter(!is.na(llon)) %>%  # Also drop any NA lag longitudes (i.e. the first detection of each)
  mutate(bearing=argosfilter::bearing(llat, lat, llon, lon)) %>% # use mutate and argosfilter to add bearings!
  mutate(dist=argosfilter::distance(llat, lat, llon, lon)) # use mutate and argosfilter to add distances!


View(st_summary)
dim(st_summary) # only 192,000 'animal changed location' entries, down from 1.5m!

# Caveat: these new measurements are based on linear transitions, which is usually incorrect.
# marmap can ue bathymetry to do a shortest-path distance between two points in water, as we will see in glatos anim.


# 4.1: Exploring our processed data

st_summary %>% 
  group_by(tag.ID) %>% 
  mutate(cdist=cumsum(dist)) %>% 
  ggplot(aes(dt, cdist, colour=tag.ID))+ geom_step()+
  facet_wrap(~Species) +
  guides(colour=F)

st_summary %>% 
  filter(dist>2) %>% 
  ggplot(aes(bearing, fill=Species))+
  # geom_histogram()+  # could do a histogram
  geom_density()+      # and/or a density plot
  facet_wrap(~Species) +  # one facet per species
  coord_polar()

# You'd probably do more filtering before arriving at this point, lots of detections at individual receivers might skew this particular plot,
# but as an example of how to plot the results of telemetry it's a good example.


## Networks of Stations and Animals using Detections ####

# 5.1: Networks are just connections between nodes and we can draw a simple one

st_summary %>% 
  group_by(Species, lon, lat, llon, llat) %>%       # we handily have a pair of locations on each row from last example to group by
  summarise(n=n()) %>%                              # count the number of rows in each group
  ggplot(aes(x=llon, xend=lon, y=llat, yend=lat))+  # xend and yend define your segments
  geom_segment()+geom_curve(colour="purple")+       # and geom_segment() and geom_curve() will connect them
  facet_wrap(~Species)+
  geom_point()                                      # draw the points as well to make them clear.

# Splitting on species can show us the different ways each species uses the network, 
# but the scale of the values of edges and nodes is hard to differentiate. 
# Let's switch our plot scale for the edges to a log scale.

st_summary %>% 
  group_by(Species, lon, lat, llon, llat) %>% 
  summarise(n=n()) %>% 
  ggplot(aes(x=llon, xend=lon, y=llat, yend=lat, size=n %>% log))+
  geom_point() + # Put this on the bottom of the plot.
  geom_segment()+geom_curve(colour="purple")+
  facet_wrap(~Species)
  

# Could label the receivers to provide context, or, 
# we can add this to our basemap to see the relationships on top of the spatial data

bplot+ # remember: we saved this bathy plot earlier
  geom_segment(data=st_summary %>% 
                 group_by(Species, lon, lat, llon, llat) %>% 
                 summarise(n=n()),
               aes(x=llon, xend=lon, y=llat, yend=lat, size=n %>% log, alpha=n %>% log), inherit.aes=F)+ # bplot has Z, nothing else does, so inherit.aes=F to ignore missing parent aesthetic values
  facet_wrap(~Species)  # we also scale alpha because we're going to force a lot of these relationship lines on top of one another with this method.

# Network Analysis - you can take things further with the igraph and ggraph packages (too much for this tutorial!), 
# but when building the source data for it as we've done here, you have to think critically about whether you're 
# intending to see trends in individuals, species, by other variables, whether regions are nodes or individuals are nodes, 
# whether a few highly detected individuals are providing most of the story in a summary like the one we made here, etc.


# Bonus Stuff - Exploring the data interactively

library(mapview)
library(spdplyr)  # this is a bit of a new package, 
                  # this will let us keep our spatial data frame 
                  # and still explore the data in the tidyverse way!



# How long would plotting all of this take? 
# A long time! And the resulting browser window will be overloaded and
# non-functional. So don't pass -too- many points to mapview!

# don't run this!
# mapview(stS)

# Instead, how could we look at a single animal? # 18,000 rows of data
# Quick and snappy.
mapview(stS %>% filter(tag.ID == "A69-1601-30617"))

# A single month?  # 100,000 rows of data, at the edge of what mapview can do comfortably
# Plotting this one takes a little longer, and the plot may be very slow to interact!
mapview(stS %>% mutate(DateTime = ymd_hms(DateTime)) %>% 
                filter(DateTime > as.POSIXct("2012-05-01") & DateTime < as.POSIXct("2012-06-01")))

# Q: how could you confirm how big a subset of your data will be 
# before you pass it to a plotting or analysis function?

# Don't forget: Investigate how big a dataset you're going to pass to a tool like mapview!


## Animating plots ####
# Telemetry data is millions of things that happened in the same places 
# over and over again through time.
# So static geographic maps don't really give a sense of what's happening!
# We could use animation to get a better picture of what each animal 
# was doing as they were using the system.

# Let's pick one animal to follow
st1<-st_summary %>% filter(tag.ID=="A69-1601-30617") 


an1<-bgo %>%  # re-use our nice-looking background object bgo from earlier this lesson
  fortify %>% # fortify it to make it ggplot-friendly
  ggplot(aes(x, y, fill=z))+ 
  geom_raster()+ # draw using a raster
  scale_fill_etopo()+ # style it using marmap::scale_fill_etopo as before
  labs(x="Longitude", y="Latitude", fill="Depth")+ # label x as long, y as lat, fill color as depth
  theme_classic()+    
  theme(legend.key.width=unit(5, "cm"), legend.position="top")+  # adjust some specific theme variables
  theme(legend.position="top")+                                  # check here for full list: https://ggplot2.tidyverse.org/reference/theme.html
  geom_point(data=st_summary %>%                 # draw the distinct lat/lon data in st as points
               as_tibble() %>%           # showing where receivers are
               distinct(lon, lat),
             aes(lon, lat), inherit.aes=F, pch=21, fill="red", size=2)+
  geom_point(data=st1 %>% filter(tag.ID=="A69-1601-30617"),   # tell ggplot how to draw our selected animal
             aes(lon, lat), inherit.aes=F, colour="purple", size=5)+ # from here, this plot is not an animation yet. an1
  transition_time(date(st1$dt))+          # with transition_time, tell gganimate what variable to use to represent time.
  labs(title = 'Date: {frame_time}')  # Variables can be supplied to change with animation.

# What is an1?
str(an1)

# an1 is now a gganim object, 
# a list of plot objects with some metadata 
# but we haven't asked gganimate to render or combine them yet...

?gganimate::animate  # To go deeper into gganimate's animate function and its features.

# Render each frame and animate!
gganimate::animate(an1)


# This lovely gif tells the story through time of one animal effectively, but we give up interactivity
# by using a gif.


# Notably: If we were to animate the paths between these blinking points, we'd be doing a lot of portage! The perils of working in a river system. 
# Next, we'll use the glatos package to help us dodge land masses better while animating transitions between stations.
