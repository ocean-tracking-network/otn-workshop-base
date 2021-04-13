## Actel Part 2 - Custom Spatial Networks:

# Let's design a spatial.txt file for our detection data

# Let's first visualize our study area, with a popup that tells us what 
# project each deployment belongs to:

# Designing a spatial.txt file -----

library(mapview)
library(spdplyr)
library(leaflet)
library(leafpop)


## Exploration - Let's use mapview, since we're going to want to move around, 
#   drill in and look at our stations


# Get a list of spatial objects to plot from actel_spatial_sum:
our_receivers <- as.data.frame(actel_spatial_sum) %>%    
  dplyr::filter(Array %in% (actel_spatial_sum %>%   # only look at the arrays already in our spatial file
                              distinct(Array))$Array)

rcvr_spatial <- our_receivers %>%    
  dplyr::select(Longitude, Latitude) %>%           # and get a SpatialPoints object to pass to mapview
  sp::SpatialPoints(CRS('+proj=longlat'))
# and plot it using mapview. The popupTable() function lets us customize our tooltip
mapview(rcvr_spatial, popup = popupTable(our_receivers, 
                                         zcol = c("Array",
                                                  "Station.name")))  # and make a tooltip we can explore

# Can we design a spatial.txt file that fits our study area using 'glatos_array' 
# as our Array?

# not really, no. Too complicated, too many interconnected arrays! 
# Let's first combine many arrays in the same area to define a Lake Huron 'zone'
# and keep the complexity for a few river systems that connect to it.

# We only need to do this in our spatial.csv file!

huron_arrays <- c('WHT', 'OSC', 'STG', 'PRS', 'FMP', 
                  'ORM', 'BMR', 'BBI', 'RND', 'IGN', 
                  'MIS', 'TBA')


# Update actel_spatial_sum to reflect the inter-connectivity of the Huron arrays.
actel_spatial_sum_lakes <- actel_spatial_sum %>% 
  dplyr::mutate(Array = if_else(Array %in% huron_arrays, 'Huron', #if any of the above, make it 'Huron'
                                Array)) # else leave it as its current value

# Notice we haven't changed any of our data or metadata, just the spatial table

# Update this with your path to glatos_spatial.txt
# If your working dir is workshop/code/day2, this path should be correct:
# spatial_txt_dot = '../../data/glatos_spatial.txt'
spatial_txt_dot = 'path/to/the/workshop/data/glatos_spatial.txt'

# How many unique spatial Arrays do we still have, now that we've combined
# so many into Huron?

actel_spatial_sum_lakes %>% dplyr::group_by(Array) %>% dplyr::select(Array) %>% unique()


# OK. let's analyze this dataset with our reduced spatial complexity

# actel::preload() with custom spatial.txt ----

actel_project <- preload(biometrics = actel_biometrics,
                         spatial = actel_spatial_sum_lakes,
                         deployments = actel_deployments,
                         detections = actel_dets,
                         dot = readLines(spatial_txt_dot),
                         tz = tz)

# We still have our orphan detection issue
c
# And we still have receivers with detections but no deployment info
e


# But now actel understands the connectivity between our arrays better!
# actel::explore() with custom spatial.txt

actel_explore_output_lakes <- explore(datapack=actel_project, report=TRUE, print.releases=FALSE)

# We no longer get the error about detections jumping across arrays!
# and we don't need to save the report
n