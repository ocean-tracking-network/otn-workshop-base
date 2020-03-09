# Using dplyr and ggplot2 to view, clean and plot telemetry data #####
# Built originally by Robert Lennox of NORCE, first version of this module delivered as part of ideasOTN in February 2020.

# To verify your environment is ready to work along with this code, try all of these imports and examine the output closely for errors.
# install.packages('name') for the packages that are missing.

# Imports
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
library(argosfilter)

# Other content not covered in this module - network analysis using igraph and ggraph, mixed-effects models.

#### Organizing your Code - Making Headers ####
# four #, -s, =s after the comment == header makes an entry.

# Getting Help with Functions/Packages ####
?barplot
args(lm)
?lm

# you could also ask Google / Stack Overflow, 
# this strategy especially good for error messages


# If you were to read in a CSV file of your own detection data:
# seaTrout <- read.csv("ideasOTNtws2020code/rl_intro/seaTrout.csv")

# Load this nice .rda file of your data. We'll explore what it looks like.
# meanwhile, this is a painless way to dump 1.5m observations into your environment
load("seaTrout.rda")

# Lots of ways to get a clue about what this variable is and how it looks

# Base R way:
str(seaTrout)

# Tidyverse option:
glimpse(seaTrout)

# Call a function to print the first few rows
# Base R way:
head(seaTrout)

# Tidyverse method of calling the head function:
seaTrout %>% head


## Chapter 1: base R and the tidyverse #####
# basic functions 1.1: subsetting
####
# Select one column by number, base and then Tidy
####
seaTrout[,c(6)]
seaTrout %>% select(6)

####
# Select the first 5 rows.
####
seaTrout[c(1:5),]
seaTrout %>% slice(1:5)

####
# basic functions 1.2: how many species do we have?
####
nrow(data.frame(unique(seaTrout$Species))) 

seaTrout %>% distinct(Species) %>% nrow
####
# basic function 1.3: format date times
####
as.POSIXct(seaTrout$DateTime) # Check if your beverage needs refilling

seaTrout %>% mutate(DateTime=ymd_hms(DateTime))  # Lightning-fast, thanks to Lubridate's ymd_hms(), 'yammed hams'!
                                                 # For datestrings in American, try dmy_hms()
####
# basic function 1.4: filtering
####
seaTrout[which(seaTrout$Species=="Trout"),]
seaTrout %>% filter(Species=="Trout")

####
# basic function 1.5: plotting
####
plot(seaTrout$lon, seaTrout$lat)  # check again if beverage is full
seaTrout %>% ggplot(aes(lon, lat))+geom_point() # sometimes plots just take time

####
# basic function 1.6: getting data summaries
####
tapply(seaTrout$lon, seaTrout$tag.ID, mean) # get the mean value across a column
seaTrout %>% 
  group_by(tag.ID) %>% 
  summarise(mean=mean(lon))   # Can use pipes and newlines to organize this process 

## Chapter 2: expanding our ggplot capacity ####

# monthly longitudinal distribution of salmon smolts and sea trout
# Benefit of piping and plus-ing in additional aesthetics and geometry - can build and rebuild partial plots

seaTrout %>% 
  group_by(m=month(DateTime), tag.ID, Species) %>% 
  summarise(mean=mean(lon)) %>% 
  ggplot(aes(m %>% factor, mean, colour=Species, fill=Species))+ # the data is supplied, but no info on how to show it!
  geom_point(size=3, position="jitter")+   # draw data as points, and use jitter to help see all points instead of superimposition
  coord_flip()+       
  scale_colour_manual(values=c("grey", "gold"))+  # change the color palette to reflect species a bit better
  scale_fill_manual(values=c("grey", "gold"))+  
  geom_boxplot()+    
  geom_violin(colour="black")


seaTrout %>% 
  group_by(m=month(DateTime), tag.ID, Species) %>% 
  summarise(mean=mean(lon)) %>% 
  ggplot(aes(m, mean, colour=Species, fill=Species))+
  geom_point(size=3, position="jitter")+
  coord_flip()+
  scale_colour_manual(values=c("grey", "gold"))+
  scale_fill_manual(values=c("grey", "gold"))+
  geom_density2d(size=2, lty=1)


seaTrout %>% 
  group_by(m=month(DateTime), tag.ID, Species) %>% 
  summarise(mean=mean(lon)) %>% 
  ggplot(aes(m, mean))+
  stat_density_2d(aes(fill = stat(nlevel)), geom = "polygon")+
  #geom_point(size=3, position="jitter")+
  coord_flip()+
  facet_wrap(~Species)+
  scale_fill_viridis_c() +
  labs(x="Mean Month", y="Longitude (UTM 33)")

# per-individual density contours - lots of facets
seaTrout %>% 
  ggplot(aes(lon, lat))+
  stat_density_2d(aes(fill = stat(nlevel)), geom = "polygon")+
  facet_wrap(~tag.ID)


## Chapter 3: Handling spatial objects in R ####

library(rgdal)
library(rgeos)

# we have coordinates in UTM, a metric based projection
# we want to work with latitude longitdude, so we must convert

# Say that stS is a copy of our seaTrout data
stS<-seaTrout 

# note: both the sp and raster libraries can provide these functions
# Currently we're using sp brought in w/ rgeos

coordinates(stS)<-~lon+lat # tell stS that it's a spatial data frame with coordinates in lon and lat
proj4string(stS)<-CRS("+proj=utm +zone=33 +ellps=WGS84 +datum=WGS84 +units=m +no_defs") # in reference system UTM 33


# We'd like to project this into longlat - but spTransform can take this to any projection / coordinate reference system we need.
st<-spTransform(stS, CRS("+init=epsg:28992"))   # what is epsg:28992 - https://epsg.io/28992 - netherlands/dutch topographic map in easting/northing
st<-data.frame(st)  # results aren't a data.frame by default though.
View(st)  # It knows the coords should go in lon and lat columns, but they're actually easting/northing now as per the CRS.

st<-spTransform(stS, CRS("+proj=longlat +datum=WGS84")) # ok let's put it in lat/lon WGS84
st<-data.frame(st)
View(st)

# So now we have a spatially-aware data frame, using lat and lon as its coordinates in the appropriate CRS
# we want to see the underlying study area, we can use the min/max of our lat lon to subset a world map 
# or to fetch a terrain/bathy map from NOAA using marmap

x=.5 # padding for our bounds
st<- st %>% as_tibble(st) # put our data back into tibble form explicitly
bgo <- getNOAA.bathy(lon1 = min(st$lon-x), lon2 = max(st$lon+x),
                     lat1 = min(st$lat-x), lat2 = max(st$lat+x), resolution = 1) # higher resolutions are very big.
class(bgo); bgo %>% class # same %>% concept as before, these are just two ways of doing the same thing 
plot(bgo) # what's a 'bathy' object?
plot(bgo, col="royalblue")
autoplot(bgo)
# Turn the raster into a data.frame for easy plotting and then into a tibble.
# This works for any raster file! Turn it into a square matrix and let it be a tibble.
bgo %>% fortify %>% as_tibble   

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

bplot<-bgo %>%  # Save the output of the plot call to a variable instead of showing it.
  fortify %>%  # Turn a raster into a data.frame 
  ggplot(aes(x, y, z=z, fill=z))+  
  geom_raster()+       # raster-ify
  scale_fill_etopo()+  # color in the pixels
  labs(x="Longitude", y="Latitude", fill="Depth")+
  theme_classic()+
  theme(legend.position="top") +
  geom_point(data=st %>% 
               as_tibble() %>% 
               distinct(lon, lat),
             aes(lon, lat), inherit.aes=F, pch=21, fill="red", size=2)+ # don't inherit aesthetics from the parent, 
                                                                        # original map is lat/lon/depth, points without Z vals will fail to plot!
  theme(legend.key.width = unit(5, "cm"))

bplot  # now that it's in bplot, here's how you can show it if you need to.

####
## Chapter 4: More tidy functions you may encounter in your workflow ####
####

# Filtering and data processing 

st<-as_tibble(st) # make sure st is a tibble again for speed's sake

# One pipe to fix dates, 
# filter subsets, 
# calculate lead and lag locations,
# and calculate new derived values, in this case, bearing and distance.

st<-st %>%  # overwrite the dataframe with the result of this pipe!
  mutate(dt=ymd_hms(DateTime)) %>% 
  dplyr::select(-1, -2, -DateTime) %>%  # Don't return DateTime, or column 1 or 2 of the data
 # filter(month(dt)>5 & month(dt)<10) %>%  # filter for just a range of months?
  arrange(dt) %>% 
  group_by(tag.ID) %>% 
  mutate(llon=lag(lon), llat=lag(lat)) %>%  # lag longitude, lag latitude (previous position)
  filter(lon!=lag(lon)) %>%  # If you didn't change positions, drop this row.
  rowwise() %>% 
  filter(!is.na(llon)) %>%  # Also drop any NA lag longitudes (i.e. the first detection of each)
  mutate(bearing=argosfilter::bearing(llat, lat, llon, lon)) %>% # use mutate and argosfilter to add bearings!
  mutate(dist=argosfilter::distance(llat, lat, llon, lon)) # use mutate and argosfilter to add distances!


View(st)

# Caveat: these new measurements are based on linear transitions, which is usually incorrect.
# marmap can ue bathymetry to do a shortest-path distance between two points in water, as we will see in glatos anim.


# 4.1: Exploring our processed data

st %>% 
  group_by(tag.ID) %>% 
  mutate(cdist=cumsum(dist)) %>% 
  ggplot(aes(dt, cdist, colour=tag.ID))+ geom_step()+
  facet_wrap(~Species) +
  guides(colour=F)

st %>% 
  filter(dist>2) %>% 
  ggplot(aes(bearing, fill=Species))+
  # geom_histogram()+  # could do a histogram
  geom_density()+      # and/or a density plot
  facet_wrap(~Species) +  # one facet per species
  coord_polar()

# You'd probably do more filtering before arriving at this point, lots of detections at individual receivers might skew this particular plot,
# but as an example of how to plot the results of telemetry it's a good example.


## Chapter 5: Networks of Stations and Animals using Detections ####

# 5.1: Networks are just connections between nodes and we can draw a simple one

st %>% 
  group_by(Species, lon, lat, llon, llat) %>%       # we handily have a pair of locations on each row from last example to group by
  summarise(n=n()) %>%                              # count the number of rows in each group
  ggplot(aes(x=llon, xend=lon, y=llat, yend=lat))+  # xend and yend define your segments
  geom_segment()+geom_curve(colour="purple")+       # and geom_segment() and geom_curve() will connect them
  facet_wrap(~Species)+
  geom_point()                                      # draw the points as well to make them clear.

st %>% 
  group_by(Species, lon, lat, llon, llat) %>% 
  summarise(n=n()) %>% 
  ggplot(aes(x=llon, xend=lon, y=llat, yend=lat, size=n %>% log))+
  geom_point() + # Put this on the bottom of the plot.
  geom_segment()+geom_curve(colour="purple")+
  facet_wrap(~Species)
  

# 5.2: Could label the receivers to provide context, or, we can add this to our map to see the relationships on top of the spatial data

bplot+ # we saved this earlier when doing bathymetry plotting
  geom_segment(data=st %>% 
                 group_by(Species, lon, lat, llon, llat) %>% 
                 summarise(n=n()),
               aes(x=llon, xend=lon, y=llat, yend=lat, size=n %>% log, alpha=n %>% log), inherit.aes=F)+ # bplot has Z, nothing else does, so inherit.aes=F to ignore missing parent aesthetic values
  facet_wrap(~Species)  # we also scale alpha because we're going to force a lot of these relationship lines on top of one another with this method.

# Network Analysis - you can take things further with the igraph and ggraph packages (too much for this tutorial!), 
# but when building the source data for it as we've done here, you have to think critically about whether you're 
# intending to see trends in individuals, species, by other variables, whether regions are nodes or individuals are nodes, 
# whether a few highly detected individuals are providing most of the story in a summary like the one we made here, etc.


## Chapter 6: Animating plots ####

# Let's pick one animal to follow
st1<-st %>% filter(tag.ID=="A69-1601-30617") # another great time to check hydration levels

an1<-bgo %>%
  fortify %>% 
  ggplot(aes(x, y, fill=z))+
  geom_raster()+
  scale_fill_etopo()+
  labs(x="Longitude", y="Latitude", fill="Depth")+
  theme_classic()+
  theme(legend.key.width=unit(5, "cm"), legend.position="top")+
  theme(legend.position="top")+
  geom_point(data=st %>% 
               as_tibble() %>% 
               distinct(lon, lat),
             aes(lon, lat), inherit.aes=F, pch=21, fill="red", size=2)+
  geom_point(data=st1 %>% filter(tag.ID=="A69-1601-30617"),
             aes(lon, lat), inherit.aes=F, colour="purple", size=5)+ # from here, this plot is not an animation yet. an1
  transition_time(date(st1$dt))+
  labs(title = 'Date: {frame_time}')  # Variables supplied to change with animation.

# an1 is now a list of plot objects but we haven't plotted them.

?gganimate::animate  # To go deeper into gganimate's animate function and its features.

gganimate::animate(an1)

# Notably: we're doing a lot of portage! The perils of working in a river system. 
# Later we'll use the glatos package to help us dodge land masses better in our transitions.


## Chapter 7: Some hypothesis tests

# H1: Trout moved farther seaward in the summer
# Plotting all points from here on out, this can take a long time!

st %>% 
  filter(Species=="Trout") %>% 
  ggplot(aes(dt, lon))+
  geom_point()

st %>% 
  ggplot(aes(dt %>% yday, lon))+
  geom_point()+
  geom_smooth(method="lm")

st %>% 
  filter(Species=="Trout") %>% 
  ggplot(aes(dt %>% yday, lon %>% log))+
  geom_point()+
  geom_smooth()




