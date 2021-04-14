## Actel Part 2 - Custom Spatial Networks:

# Let's design a spatial.txt file for our detection data

# Let's first visualize our study area, with a popup that tells us what 
# project each deployment belongs to:

# Designing a spatial.txt file -----

library(leaflet)



# Get a list of spatial objects to plot from actel_spatial_sum:
our_receivers <- as.data.frame(actel_spatial_sum) %>%    
  dplyr::filter(Array %in% (actel_spatial_sum %>%   # only look at the arrays already in our spatial file
                              distinct(Array))$Array)

m <- leaflet() %>% addTiles() %>% addMarkers(lng=our_receivers$Longitude, lat=our_receivers$Latitude, popup=our_receivers$Array)

m
# Can we design a spatial.txt file that fits our study area using 'collectioncode' 
# as our Array?

# not really, no. Too complicated, too many interconnected arrays! Let's define most of our projects as
# Outside, that is, outside our estuary/river system, not really subject to being interconnected


# We only need to do this in our spatial.csv file!

# projects in relatively 'open' water:
outside_arrays <- c('PROJ87', 'PROJ128', 'PROJ127', 'PROJ122', 'PROJ100', 
                   'PROJ132', 'PROJ125', 'PROJ121', 
                  'PROJ133', 'PROJ131', 'PROJ138', 'PROJ89', 'PROJ56', 
                  'PROJ61POCOMO', 'PROJ61LTEAST', 'PROJ61LTWEST', 
                  'PROJ61CORNHB')

# the Florida station we'll group separately
wilmington <- c('PROJ61NCFPT', 'PROJ61NDBC41037', 'PROJ61CORMPOB27', 
                'PROJ61NDBC41038', 'PROJ61NDBC41064')

# Within the Chesapeake area:
# Piney Point's a gate array
piney_point <-c('PROJ60PINEY POINT A', 'PROJ60PINEY POINT B', 
                'PROJ60PINEY POINT C', 'PROJ60PINEY POINT D')

# the RTE 301 receivers are a group.
rte_301 <- c('PROJ60RT 301 A', 'PROJ60RT 301 B')

cedar_point <- c('PROJ60CEDAR POINT A', 'PROJ60CEDAR POINT B', 
                 'PROJ60CEDAR POINT C', 'PROJ60CEDAR POINT D',
                 'PROJ60CEDAR POINT E')

ccb_kent <- c('PROJ60CCB1', 'PROJ60CCB2', 'PROJ60CCB3', 'PROJ60CCB4',
              'PROJ60KENT ISLAND A', 'PROJ60KENT ISLAND B', 
              'PROJ60KENT ISLAND C', 'PROJ60KENT ISLAND D')
bear_cr <- c('PROJ61BEARCR', 'PROJ61BEARCR2')

# Single receivers inside the Chesapeake:
ches_rcvrs <- c('PROJ61COOKPT','PROJ61NELSON','PROJ61CASHAV',
                'PROJ61TPTSH','PROJ61SAUNDR', 'PROJ61DAVETR')

rhode_r <- c('PROJ61WESTM', 'PROJ61RHODEM', 'PROJ61RMOUTH')

# Update actel_spatial_sum to reflect the inter-connectivity of the Huron arrays.
actel_spatial_sum_grouped <- actel_spatial_sum %>% 
  dplyr::mutate(Array = if_else(Array %in% outside_arrays, 'Outside', #if any of the above, make it 'Huron'
                                Array)) %>% # else leave it as its current value
  dplyr::mutate(Array = if_else(Array %in% wilmington, 'Wilmington', Array)) %>%
  dplyr::mutate(Array = if_else(Array %in% ches_rcvrs, 'InnerChesapeake', Array)) %>%
  dplyr::mutate(Array = if_else(Array %in% piney_point, 'PROJ60PineyPoint', Array)) %>%
  dplyr::mutate(Array = if_else(Array %in% rte_301, 'PROJ60RTE301', Array)) %>%
  dplyr::mutate(Array = if_else(Array %in% rhode_r, 'PROJ61RHODER', Array)) %>%
  dplyr::mutate(Array = if_else(Array %in% cedar_point, 'PROJ60CEDARPOINT', Array)) %>%
  dplyr::mutate(Array = if_else(Array %in% ccb_kent, 'CCBKENT', Array)) %>%
  dplyr::mutate(Array = if_else(Array %in% bear_cr, 'PROJ60BEARCR', Array)) %>%
  dplyr::mutate(Array = if_else(Station.name %in% c('PROJ56-UP', 'Woodrow Wilson Bridge'),'PROJ56-UP', Array)) %>% # one tricky receiver?
  dplyr::mutate(Array = if_else(Station.name == 'PROJ56-SN', 'PROJ56-SN', Array)) %>%
  dplyr::mutate(Array = if_else(Array == 'PROJ60CD WEST LL 9200', 'PROJ60CDWESTLL9200', Array)) %>%
  dplyr::mutate(Array = if_else(Array == 'PROJ60CBL PIER', 'PROJ60CBLPIER', Array))# two tricky receivers?
# Notice we haven't changed any of our data or metadata, just the spatial table


# Head back into the map, and denote the connectivity between our receiver groups:

m <- leaflet() %>% addTiles() %>% 
  addMarkers(lng=actel_spatial_sum_grouped$Longitude, 
             lat=actel_spatial_sum_grouped$Latitude, 
             popup=actel_spatial_sum_grouped$Array)

m

# create and curate your spatial.txt file. Here's an example of how complicated 
# they can get in large systems:
spatial_txt_dot = 'act_spatial.txt'

# How many unique spatial Arrays do we still have, now that we've combined
# so many?

actel_spatial_sum_grouped %>% dplyr::group_by(Array) %>% dplyr::select(Array) %>% unique()


# OK. let's analyze this dataset with our reduced spatial complexity

# actel::preload() with custom spatial.txt ----

actel_project <- preload(biometrics = actel_biometrics,
                         spatial = actel_spatial_sum_grouped,
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