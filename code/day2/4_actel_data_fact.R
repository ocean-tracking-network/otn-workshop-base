# Using FACT-style data in Actel ####

library(actel)
library(stringr)
library(glatos)
library(tidyverse)
library(readxl)

# set working directory to the data folder for this workshop
setwd('YOUR/PATH/TO/data/fact')

#Add this for when we read in the file. 
format <- cols( # Heres a col spec to use when reading in the files
  .default = col_character(),
  datelastmodified = col_date(format = ""),
  bottom_depth = col_double(),
  receiver_depth = col_double(),
  sensorname = col_character(),
  sensorraw = col_character(),
  sensorvalue = col_character(),
  sensorunit = col_character(),
  datecollected = col_datetime(format = ""),
  longitude = col_double(),
  latitude = col_double(),
  yearcollected = col_double(),
  monthcollected = col_double(),
  daycollected = col_double(),
  julianday = col_double(),
  timeofday = col_double(),
  datereleasedtagger = col_logical(),
  datereleasedpublic = col_logical()
)

# Our project's detections file - I'll use readr to read everything from TQCS in at once:
proj_dets <- list.files(pattern="tqcs_*.zip") %>% 
  map_df(~readr::read_csv(.))
# note: readr::read_csv will read in csvs inside zip files no problem.

proj_dets <- tibble()
for (detfile in list.files('.', full.names = TRUE, pattern = "tqcs.*\\.zip")) {
  print(detfile)
  tmp_dets <- read_csv(detfile, col_types = format)
  proj_dets <- bind_rows(proj_dets, tmp_dets)
}

#Filter out all the non-TEQ detections. 
proj_dets <- proj_dets %>% 
  distinct() %>% 
  filter(receiver != "release") %>% 
  filter(detectedby == 'TEQ') %>%
  slice(1:100000)

# read in the tag metadata:
tag_metadata <- readr::read_csv('TQCS_metadata_tagging.csv')

deploy_metadata <- read_csv('') %>%
  # Add a very quick and dirty receiver group column.
  mutate(rcvrgroup = ARRAY)
# Also tried to figure out if there was a pattern to station naming that we could take advantage of
# but nothing obvious materialized.
# mutate(rcvrgroup = paste(collectioncode, stringr::str_replace_all(station_name, "[:digit:]", ""), sep='_'))

deploy_metadata <- read_csv('TEQ_Deployments_201001_201201.csv') %>%
  # Add a very quick and dirty receiver group column.
  mutate(rcvrgroup = ifelse(ARRAY %in% c('TQCS', 'TEQ'), # if we're talking PROJ61
                            paste0(ARRAY,STATION_NO), #let my receiver group be the station name
                            collectioncode)) # for other project receivers just make it their whole project code.

# Let's review the groups quickly to see if we under or over-shot what our receiver groups should be.
# nb. hiding the legend because there are too many categories.
deploy_metadata %>% ggplot(aes(DEPLOY_LAT, DEPLOY_LONG, colour=rcvrgroup)) + 
  geom_point() + 
  theme(legend.position="none")

# Maybe this is a bit of an overshoot, but it should work out. proj61 has receivers all over the place, 
# so our spatial analysis is not going to be very accurate.


# And let's look at what the other projects were that detected us.
proj_dets %>% count(detectedby)

# And how many of our tags are getting detections back:
proj_dets %>% filter(receiver != 'release') %>% count(tagname)

# OK most of those who have more than an isolated detection are in our deploy metadata.
# just one OTN project to add.

# For OTN projects, we would be able to add in any deployments of OTN receivers from the OTN GeoServer:

# if we wanted to grab and add V2LGMXSNAP receivers to our deployment metadata
# using OTN's public station history records on GeoServer:
# otn_geoserver_stations_url = 'https://members.oceantrack.org/geoserver/otn/ows?service=WFS&version=1.0.0&request=GetFeature&typeName=otn:stations_receivers&outputFormat=csv&cql_filter=collectioncode=%27V2LGMXSNAP%27'
## TODO: Actel needs serial numbers for receivers, so OTN 
#  will add serial numbers to this layer, and then we can just
#  urlencode the CQL-query for which projects you want, 
#  so you can write your list in 'plaintext' and embed it in the url

# For today, we've made an extract for V2LGMXSNAP and included it in the data folder:
otn_deploy_metadata <- readr::read_csv('otn_moorings_receivers_202104130938.csv') %>%
  mutate(rcvrgroup = collectioncode)

# Tack OTN stations to the end of the MATOS extract.
# These are in the exact same format because OTN and MATOS's databases are the
# same format, so we can easily coordinate our output formats.
all_stations <- bind_rows(deploy_metadata, otn_deploy_metadata)

# For ACT/FACT projects - we could use GeoServer to share this information, and could even add
# an authentication layer to let ACT members do this same trick to fetch deploy histories!

# So now this is our animal tagging metadata
# tag_metadata %>% View

# these are our detections: 

# proj_dets %>% View

# These are our deployments:

# all_stations %>% View

# Mutate metadata into Actel format ----

# Create a station entry from the glatos array and station number.
# --- add station to receiver metadata ----
full_receiver_meta <- all_stations %>%
  dplyr::mutate(
    station = paste(collectioncode, station_name, sep = '-')
  ) %>% 
  filter(is.na(rcvrstatus)|rcvrstatus != 'lost')

# Actel Biometrics ------------

# All dates will be supplied to Actel in this format:
actel_datefmt = '%Y-%m-%d %H:%M:%S'

# biometrics is the tag metadata. If you have a tag metadata sheet, it looks like this:
actel_biometrics <- tag_metadata %>% dplyr::mutate(Release.date = format(UTC_RELEASE_DATE_TIME, actel_datefmt),
                                                   Signal=as.integer(TAG_ID_CODE),
                                                   Release.site = RELEASE_LOCATION, 
                                                   # Group=RELEASE_LOCATION  # can supply group to subdivide tagging groups
)
# Actel Deployments ----
# deployments is based in the receiver deployment metadata sheet
actel_deployments <- full_receiver_meta %>% dplyr::filter(!is.na(recovery_date)) %>%
  mutate(Station.name = station,
         Start = format(deploy_date, actel_datefmt), # no time data for these deployments
         Stop = format(recovery_date, actel_datefmt),  # not uncommon for this region
         Receiver = rcvrserial) %>%
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
                                                         Latitude = deploy_lat,
                                                         Longitude = deploy_long,
                                                         Type='Hydrophone') %>%
  dplyr::mutate(Array=rcvrgroup) %>%    # Having too many distinct arrays breaks things.
  dplyr::select(Station.name, Latitude, Longitude, Array, Type) %>%
  distinct(Station.name, Latitude, Longitude, Array, Type)

# Actel Tag Releases ---------------

# Prepare and style entries for tag releases
actel_tag_releases <- tag_metadata %>% mutate(Station.name = RELEASE_LOCATION,
                                              Latitude = RELEASE_LATITUDE,
                                              Longitude = RELEASE_LONGITUDE,
                                              Type='Release') %>%
  # It's helpful to associate release locations with their nearest Array.
  # Could set all release locations to the same Array:
  #  mutate(Array = 'PROJ61JUGNO_2A') %>% # Set this to the closest array to your release locations
  # if this is different for multiple release groups, can do things like this to subset case-by-case:
  # here Station.name is the release location 'station' name, and the value after ~ will be assigned to all.
  mutate(Array = case_when(Station.name %in% c('Red Banks', 'Eldorado', 'Williamsburg') ~ 'PROJ61UTEAST', 
                           Station.name == 'Woodrow Wilson Bridge' ~ 'PROJ56',
                           Station.name == 'Adjacent to Lyons Creek' ~ 'PROJ61JUGNO_5',
                           Station.name == 'Merkle Wildlife Sanctuary' ~ 'PROJ61JUGNO_2A',
                           Station.name == 'Nottingham' ~ 'PROJ61NOTTIN',
                           Station.name == 'Sneaking Point' ~ 'PROJ61MAGRUD',
                           Station.name == 'Jug Bay Dock' ~ 'PROJ61JUGDCK')) %>% # This value needs to be the nearest array to the release site
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


