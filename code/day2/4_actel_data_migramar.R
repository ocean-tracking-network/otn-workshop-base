# Using ACT-style data in Actel ####

library(actel)
library(stringr)
library(glatos)
library(tidyverse)
library(readxl)

# set working directory to the data folder for this workshop
setwd("YOUR/PATH/TO/data/migramar")

# Our project's detections file - I'll use readr to read everything from proj59 in at once:

proj_dets <- list.files(pattern="gmr_matched_detections*") %>% 
  map_df(~readr::read_csv(.))
# note: readr::read_csv will read in csvs inside zip files no problem.


# read in the tag metadata:

tag_metadata <- readxl::read_excel('gmr_tagging_metadata.xls', 
                                   sheet='Tag Metadata'# use the Tag Metadata sheet from this excel file
                                   ) # skip the first 4 lines as they're 'preamble'


# And we can import first a subset of the deployments in MATOS that were deemed OK to publish
deploy_metadata <- readxl::read_excel('gmr-deployment-short-form.xls', sheet='Deployment') %>%
  # Add a very quick and dirty receiver group column.
  mutate(rcvrgroup = ifelse(OTN_ARRAY %in% c('GMR'), # if we're talking GMR
                            paste0(OTN_ARRAY,STATION_NO), #let my receiver group be the station name
                            OTN_ARRAY)) # for other project receivers just make it their whole project code.

# Also tried to figure out if there was a pattern to station naming that we could take advantage of
# but nothing obvious materialized.
# mutate(rcvrgroup = paste(collectioncode, stringr::str_replace_all(station_name, "[:digit:]", ""), sep='_'))

# Let's review the groups quickly to see if we under or over-shot what our receiver groups should be.
# nb. hiding the legend because there are too many categories.
deploy_metadata %>% ggplot(aes(DEPLOY_LAT, DEPLOY_LONG, colour=rcvrgroup)) + 
  geom_point() + 
  theme(legend.position="none")

# And let's look at what the other projects were that detected us.
proj_dets %>% count(detectedby)

# And how many of our tags are getting detections back:
proj_dets %>% filter(receiver != 'release') %>% count(tagname)

# Mutate metadata into Actel format ----

# Create a station entry from the glatos array and station number.
# --- add station to receiver metadata ----
full_receiver_meta <- deploy_metadata %>%
  dplyr::mutate(
    station = paste(OTN_ARRAY, STATION_NO, sep = '-')
  ) %>% 
  filter(is.na(`RECOVERED (y/n/l)`)|`RECOVERED (y/n/l)` != 'lost')

# Actel Biometrics ------------

# All dates will be supplied to Actel in this format:
actel_datefmt = '%Y-%m-%d %H:%M:%S'

# biometrics is the tag metadata. If you have a tag metadata sheet, it looks like this:
actel_biometrics <- tag_metadata %>% dplyr::mutate(Release.date = format(as.POSIXct(UTC_RELEASE_DATE_TIME), actel_datefmt),
                                                   Signal=as.integer(TAG_ID_CODE),
                                                   Release.site = `RELEASE_LOCATION (SITIO DE MARCAJE)`, 
                                                   # Group=RELEASE_LOCATION  # can supply group to subdivide tagging groups
)
# Actel Deployments ----
# deployments is based in the receiver deployment metadata sheet
actel_deployments <- full_receiver_meta %>% dplyr::filter(!is.na(`RECOVER_DATE_TIME (yyyy-mm-ddThh:mm:ss)`)) %>%
  mutate(Station.name = station,
         Start = format(as.POSIXct(`DEPLOY_DATE_TIME   (yyyy-mm-ddThh:mm:ss)`), actel_datefmt), # no time data for these deployments
         Stop = format(as.POSIXct(`RECOVER_DATE_TIME (yyyy-mm-ddThh:mm:ss)`), actel_datefmt),  # not uncommon for this region
         Receiver = INS_SERIAL_NO) %>%
  arrange(Receiver, Start)


# Actel Detections -------------------

# Renaming some columns in the Detection extract files   
actel_dets <- proj_dets %>% dplyr::filter(receiver != 'release') %>%
  dplyr::mutate(Transmitter = tagname,
                Receiver = as.integer(receiver),
                Timestamp = format(datecollected, actel_datefmt),
                CodeSpace = extractCodeSpaces(tagname),
                Signal = extractSignals(tagname), 
                Sensor.Value = sensorvalue,
                Sensor.Unit = sensorunit)

# We don't have any environmental data in our detection extract here, but Actel 
# will also find and plot temperature or other sensor values if you have those
# kinds of tags.

# Actel Receivers-------------------

# Prepare and style entries for receivers
actel_receivers <- full_receiver_meta %>% dplyr::mutate( Station.name = station,
                                                         Latitude = DEPLOY_LAT,
                                                         Longitude = DEPLOY_LONG,
                                                         Type='Hydrophone') %>%
  dplyr::mutate(Array=rcvrgroup) %>%    # Having too many distinct arrays breaks things.
  dplyr::select(Station.name, Latitude, Longitude, Array, Type) %>%
  distinct(Station.name, Latitude, Longitude, Array, Type)

# Actel Tag Releases ---------------

# Prepare and style entries for tag releases
actel_tag_releases <- tag_metadata %>% mutate(Station.name = `RELEASE_LOCATION (SITIO DE MARCAJE)`,
                                              Latitude = RELEASE_LATITUDE,
                                              Longitude = RELEASE_LONGITUDE,
                                              Type='Release') %>%
  # It's helpful to associate release locations with their nearest Array.
  # Could set all release locations to the same Array:
  #  mutate(Array = 'PROJ61JUGNO_2A') %>% # Set this to the closest array to your release locations
  # if this is different for multiple release groups, can do things like this to subset case-by-case:
  # here Station.name is the release location 'station' name, and the value after ~ will be assigned to all.
  mutate(Array = case_when(Station.name %in% c('Derrumbe Wolf',
                                               'Darwin Anchorage',
                                               'Mosquera inside',
                                               'Puerto Baltra',
                                               'Bachas',
                                               'Playa Millonarios Baltra',
                                               'La Seca',
                                               'Punta Vicente Roca') ~ 'GMRWolf_Derrumbe', 
                           Station.name %in% c('Wolf Anchorage',
                                               'Wolf Fondeadero') ~ 'GMRWolf_Shark Point',
                           Station.name %in% c('Arco Darwin',
                                               'Darwin, Galapagos') ~ 'GMRDarwin_Cleaning Station',
                           Station.name %in% c('Manuelita, Cocos',
                                               'West Cocos Seamount') ~ 'GMRDarwin_Bus stop'
                           )) %>% # This value needs to be the nearest array to the release site
  distinct(Station.name, Latitude, Longitude, Array, Type)


# Combine Releases and Receivers ------

# Bind the releases and the deployments together for the unique set of spatial locations
actel_spatial <- actel_receivers %>% bind_rows(actel_tag_releases)

# Summarize and take mean locations for stations---------

# group by station name and take the mean lat and lon of each station deployment history.
actel_spatial_sum <- actel_spatial %>% dplyr::group_by(Station.name, Type) %>%
  dplyr::summarize(Latitude = mean(Latitude),
                   Longitude = mean(Longitude),
                   Array =  first(Array))


# Using actel::preload() naively ------------------------

# Specify the timezone that your timestamps are in.
# OTN provides them in UTC/GMT.
# FACT has both UTC/GMT and Eastern
# GLATOS provides them in UTC/GMT
# If you got the detections from someone else,
#    they will have to tell you what TZ they're in!
#    and you will have to convert them before importing to Actel!

tz <- "GMT0"

# You've collected every piece of data and metadata and formatted it properly.
# Now you can create the Actel project object.

actel_project <- preload(biometrics = actel_biometrics,
                         spatial = actel_spatial_sum,
                         deployments = actel_deployments,
                         detections = actel_dets,
                         tz = tz)

# Alas, we're going to have to discard a bunch of detections here, 
# as our subsetted demo data doesn't have deployment metadat for certain 
# receivers / time periods and is missing some station deployments

e # discard all detections at unknown receivers - this is almost never
# what you want to do in practice. Ask for missing metadata before
# resorting to this one!

# actel::explore() ----

# Get summary reports from our dataset:
actel_explore_output <- explore(datapack=actel_project, 
                                report=TRUE, GUI='never',
                                print.releases=FALSE)

n  # don't render any movements invalid - repeat for each tag, because:
# we haven't told Actel anything about which arrays connect to which
# so it's not able to properly determine which movements are valid/invalid

n  # don't save a copy of the results to a RData object... this time.

# Review the output .html file that has popped up in a browser.
# Our analysis might not make a lot of sense, since...
# actel assumed our study area was linear, we didn't tell it otherwise!


