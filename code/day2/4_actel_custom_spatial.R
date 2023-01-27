## Actel Part 2 - Custom Spatial Networks:

# Let's design a spatial.txt file for our detection data

# Let's first visualize our study area, with a popup that tells us what 
# project each deployment belongs to:

# Designing a spatial.txt file -----

# TODO: nicest possible interactive map of our study area subset.
library(ggplot2)
library(ggmap)
library(plotly)

# Subset our study area so we're not dealing with too much stuff.

# Where were we detected, excluding Canada and the GoM:
actel_dets <- actel_dets %>% filter(!detectedby %in% c('OTN.V2LGMXSNAP', 'OTN.V2LSTANI', 'OTN.V2LSTADC'))

bbox.minlat <- min(actel_dets$latitude) - 0.5
bbox.maxlat <- max(actel_dets$latitude) + 0.5
bbox.minlong <- min(actel_dets$longitude) - 0.5
bbox.maxlong <- max(actel_dets$longitude) + 1.5

actel_deployments <- actel_deployments %>% filter(between(deploy_lat, bbox.minlat, bbox.maxlat) &
                                                    between(deploy_long, bbox.minlong, bbox.maxlong))

actel_receivers <- actel_receivers %>% filter(Station.name %in% actel_deployments$Station.name)

# biometrics? maybe don't have to?

actel_spatial_sum <- actel_spatial_sum %>% filter(Station.name %in% actel_deployments$Station.name)

base <- get_stamenmap(
  bbox = c(left = min(actel_deployments$deploy_long), 
           bottom = min(actel_deployments$deploy_lat), 
           right = max(actel_deployments$deploy_long), 
           top = max(actel_deployments$deploy_lat)),
  maptype = "toner", 
  crop = FALSE,
  zoom = 12)


proj59_zoomed_map <- ggmap(base, extent='panel') + 
                      ylab("Latitude") +
                      xlab("Longitude") +
                      geom_point(data = actel_spatial_sum, 
                        aes(x = Longitude,y = Latitude, colour = Station.name),
                        shape = 19, size = 2) 
ggplotly(proj59_zoomed_map)




# Can we design a spatial.txt file that fits our study area using 'collectioncode' 
# as our Array?

# not really, no. Too complicated, too many interconnected arrays! Let's define most of our projects as
# Outside, that is, outside our estuary/river system, not really subject to being interconnected

# We only need to do this in our spatial.csv file!

# projects in relatively 'open' water:
outside_arrays <- c('PROJ56',
                    'PROJ61CORNHB', 'PROJ61POCOMO', 
                    'PROJ61LTEAST', 'PROJ61LTWEST')

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

# Update actel_spatial_sum to reflect the inter-connectivity of the Chesapeake arrays

actel_spatial <- actel_receivers %>% bind_rows(actel_tag_releases)

# Summarize and take mean locations for stations---------

# group by station name and take the mean lat and lon of each station deployment history.
actel_spatial_sum <- actel_spatial %>% dplyr::group_by(Station.name, Type) %>%
  dplyr::summarize(Latitude = mean(Latitude),
                   Longitude = mean(Longitude),
                   Array =  first(Array))

actel_spatial_sum_grouped <- actel_spatial_sum %>% 
  dplyr::mutate(Array = if_else(Array %in% outside_arrays, 'Outside', #if any of the above, make it 'Huron'
                                Array)) %>% # else leave it as its current value
#  dplyr::mutate(Array = if_else(Array %in% wilmington, 'Wilmington', Array)) %>%
  dplyr::mutate(Array = if_else(Array %in% ches_rcvrs, 'InnerChesapeake', Array)) %>%
  dplyr::mutate(Array = if_else(Array %in% piney_point, 'PROJ60PineyPoint', Array)) %>%
  dplyr::mutate(Array = if_else(Array %in% rte_301, 'PROJ60RTE301', Array)) %>%
  dplyr::mutate(Array = if_else(Array %in% rhode_r, 'PROJ61RHODER', Array)) %>%
  dplyr::mutate(Array = if_else(Array %in% cedar_point, 'PROJ60CEDARPOINT', Array)) %>%
  dplyr::mutate(Array = if_else(Array %in% ccb_kent, 'CCBKENT', Array)) %>%
  dplyr::mutate(Array = if_else(Array %in% bear_cr, 'PROJ60BEARCR', Array)) %>%
  dplyr::mutate(Array = if_else(Station.name %in% c('PROJ56-UP', 'Woodrow Wilson Bridge'),'PROJ56-UP', Array)) %>% # one tricky receiver?
  dplyr::mutate(Array = if_else(Station.name == 'PROJ56-SN', 'PROJ56-SN', Array)) %>%
  dplyr::mutate(Array = if_else(Station.name == 'PROJ56-GR', 'PROJ56-GR', Array)) %>%
#  dplyr::mutate(Array = if_else(Array == 'PROJ60CD WEST LL 9200', 'PROJ60CDWESTLL9200', Array)) %>%
  dplyr::mutate(Array = if_else(Array == 'PROJ60CBL PIER', 'PROJ60CBLPIER', Array))# two tricky receivers?
# Notice we haven't changed any of our data or metadata, just the spatial table


# Head back into the map, and denote the connectivity between our receiver groups:

proj59_arrays_map <- ggmap(base, extent='panel') + 
  ylab("Latitude") +
  xlab("Longitude") +
  geom_point(data = actel_spatial_sum_grouped, 
             aes(x = Longitude,y = Latitude, colour = Array), 
             shape = 19, size = 2) +
  geom_point(data = actel_tag_releases, aes(x=Longitude, y=Latitude, colour=Station.name),
             shape = 10, size = 5) 
ggplotly(proj59_arrays_map)


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


# Now actel understands the connectivity between our arrays better!
# actel::explore() with custom spatial.txt

actel_explore_output_chesapeake <- explore(datapack=actel_project, report=TRUE, print.releases=FALSE)

# We no longer get the error about detections jumping across arrays!
# and we don't need to save the report
n
