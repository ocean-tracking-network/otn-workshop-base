# Using GLATOS-style data in Actel ####

library(actel)
library(stringr)
library(glatos)
library(tidyverse)
#-------------

# Our project's detections file - I'll use our walleye detections
det_file <- system.file("extdata", "walleye_detections.csv", package = "glatos")

detections <- read_glatos_detections(det_file)

# Receiver deployment data: 
rec_file <- system.file("extdata", "sample_receivers.csv", package = "glatos")

receivers <- read_glatos_receivers(rec_file)

# Let's say we don't have tag metadata for the walleye. 
# Here's a way to reverse-engineer it from the walleye detections
# Don't try this at home, just use the workbook reader

tags <- detections %>% 
  dplyr::group_by('animal_id') %>% 
  dplyr::select('animal_id', 'transmitter_codespace', 
         'transmitter_id', 'tag_type', 'tag_serial_number', 
         'common_name_e', 'capture_location', 'length', 
         'weight', 'sex', 'release_group', 'release_location', 
         'release_latitude', 'release_longitude', 
         'utc_release_date_time', 'glatos_project_transmitter', 
         'glatos_tag_recovered', 'glatos_caught_date') %>%
  unique()
  
# Here's how you'd do it if you were starting with the workbook.
  
wb_file <-system.file("extdata", "walleye_workbook.xlsm", package="glatos")

wb_metadata <- glatos::read_glatos_workbook(wb_file)  

# So now this is our animal tagging metadata
wb_metadata$animals

# and this is our receiver deployment metadata
wb_metadata$receivers

# but our detections are still in this separate spot
det_file <- system.file("extdata", "walleye_detections.csv", package = "glatos")
detections <- read_glatos_detections(det_file)


# Create a station entry from the glatos array and station number.

full_receiver_meta <- wb_metadata$receivers %>%
  dplyr::mutate(
    station = paste(glatos_array, station_no, sep = '')
  )


#------------

# All dates will be supplied to Actel in this format:
actel_datefmt = '%Y-%m-%d %H:%M:%S'

# biometrics is the tag metadata. If you have a tag metadata sheet, it looks like this:
actel_biometrics <- wb_metadata$animals %>% dplyr::mutate(Release.date = format(utc_release_date_time, actel_datefmt),
                                    Signal=as.integer(tag_id_code),
                                    Release.site = release_location) %>%
  # JON DEMO ONLY: subset these tag releases to the animals we actually have 
  # detections for in our demo dataset
  # Only doing this because the demo dataset is so cut-down, wouldn't make sense
  # to have 500 tags and only 3 of them with detections.
                                    dplyr::filter(animal_id %in% tags$animal_id)

# deployments is based in the receiver deployment metadata sheet
actel_deployments <- full_receiver_meta %>% dplyr::filter(!is.na(recover_date_time)) %>%
  mutate(Station.name = station,
         Start = format(deploy_date_time, actel_datefmt), # no time data for these deployments
         Stop = format(recover_date_time, actel_datefmt),  # not uncommon for this region
         Receiver = ins_serial_no) %>%
  arrange(Receiver, Start)


#-------------------

# Renaming some columns in the Detection extract files   
actel_dets <- detections %>% dplyr::mutate(Transmitter = transmitter_id,
                                    Receiver = as.integer(receiver_sn),
                                    Timestamp = format(detection_timestamp_utc, actel_datefmt),
                                    CodeSpace = extractCodeSpaces(transmitter_id),
                                    Signal = extractSignals(transmitter_id))

#-------------------

# Prepare and style entries for receivers
actel_receivers <- full_receiver_meta %>% dplyr::mutate( Station.name = station,
                                                  Latitude = deploy_lat,
                                                  Longitude = deploy_long,
                                                  Type='Hydrophone') %>%
  dplyr::mutate(Array=glatos_array) %>%    # Having this many distinct arrays breaks things with few clues as to why.
  dplyr::select(Station.name, Latitude, Longitude, Array, Type) %>%
  distinct(Station.name, Latitude, Longitude, Array, Type)

# Prepare and style entries for tag releases
actel_tag_releases <- wb_metadata$animals %>% mutate(Station.name = release_location,
                                      Latitude = release_latitude,
                                      Longitude = release_longitude,
                                      Type='Release') %>%
  mutate(Array = 'TTB') %>% # This value needs to be the nearest array to the release site
  distinct(Station.name, Latitude, Longitude, Array, Type)





# Bind the releases and the deployments together for the unique set of spatial locations
actel_spatial <- actel_receivers %>% bind_rows(actel_tag_releases)

#-----------------------

# group by station name and take the mean lat and lon of each station deployment history.
actel_spatial_sum <- actel_spatial %>% dplyr::group_by(Station.name, Type) %>%
  dplyr::summarize(Latitude = mean(Latitude),
                   Longitude = mean(Longitude),
                   Array =  first(Array))


#------------------------

# Specify the timezone that your timestamps are in.
# OTN provides them in UTC/GMT.
# FACT has both UTC/GMT and Eastern
# GLATOS provides them in UTC/GMT
# If you got the detections from someone else, they will have to tell you what TZ they're in!

tz <- "GMT0"

# You've collected every piece of data and metadata and formatted it properly.
# Now you can create the Actel project object.
actel_project <- preload(biometrics = actel_biometrics,
                         spatial = actel_spatial_sum,
                         deployments = actel_deployments,
                         detections = actel_dets,
                         tz = tz)

# Alas, we're going to have to discard a bunch of detections here, 
# as our subsetted data doesn't have deployments for certain time periods
# and is missing some station deployments altogether!

c # discard detections outside of known deployment ranges
e # discard all detections at unknown receivers - this is almost never
  # what you want to do, but what choice do we have?

# Get summary reports from our dataset:
actel_explore_output <- explore(datapack=actel_project, 
                                report=TRUE, 
                                print.releases=FALSE)

# Our analysis doesn't make a lot of sense, since...
# actel assumed our study was linear, we didn't tell it otherwise!
# Let's design a spatial.txt file for our detection data

# Let's look at our study area, with a popup that tells us what project each deployment belongs to:

library(mapview)
library(spdplyr)
library(leaflet)
library(leafpop)


## Exploration - Let's re-use mapview, since we're going to want to drill in and look at our stations

our_receivers <- as.data.frame(actel_spatial_sum) %>%    
  dplyr::filter(Array %in% (actel_spatial_sum %>%   # Let's only look at the arrays already in our spatial file
                              distinct(Array))$Array)

mapview(our_receivers %>%    
          select(Longitude, Latitude) %>%           # and get a SpatialPoints object to pass to mapview
          SpatialPoints(CRS('+proj=longlat')), 
                    popup = popupTable(our_receivers, 
                                       zcol = c("Array",
                                                "Station.name")))  # and make a tooltip we can explore

# Can we design a spatial.txt file that fits our study area using 'glatos_array' 
# as our divider?

# not really, no. Too many interconnected arrays! 
# Let's define a Lake Huron 'zone' instead and generalize 
# a few river systems off of there.

# We only need to do this in our spatial.csv file and nowhere else!

huron_arrays <- c('WHT', 'LVD', 'OSC', 'STG', 'PRS', 'FMP', 
                  'ORM', 'BMR', 'BBI', 'RND', 'IGN', 'SIC', 
                  'GRS', 'LVU', 'TRN', 'BEI', 'MIS', 'TBA')


# Let's update our spatial to reflect the inter-connectivity of the Huron arrays.
actel_spatial_sum_lakes <- actel_spatial_sum %>% 
    dplyr::mutate(Array = if_else(Array %in% huron_arrays, 'Huron', #if any of the above, make it 'Huron'
                                       Array)) # else leave it as its current value

# Notice we haven't changed any of our data or metadata, just the spatial table

spatial_txt_dot = 'path/to/the/workshop/data/glatos_spatial.txt'

# How many unique spatial Arrays do we have now that we've combined
# so many into Huron?

actel_spatial_sum_lakes %>% dplyr::group_by(Array) %>% dplyr::select(Array) %>% unique()


# OK. let's analyze this dataset with our reduced spatial complexity

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


actel_explore_output_lakes <- explore(datapack=actel_project, report=TRUE, print.releases=FALSE)


