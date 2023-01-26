---
title: Preparing ACT/OTN/GLATOS Data for actel
teaching: 30
exercises: 0
questions:
    - "How do I take my ACT detection extracts and metadata and format them for use in `actel`?"
---

**Note to instructors: please choose the relevant Network below when teaching**

## ACT Node

### Preparing our data to use in Actel

So now, as the last piece of stock curriculum for this workshop, let's quickly look at how we can take the data reports we get from the ACT-MATOS (or any other OTN-compatible data partner, like FACT, or OTN proper) and make it ready for `Actel`.

~~~
# Using ACT-style data in Actel ####

library(actel)
library(stringr)
library(glatos)
library(tidyverse)
library(readxl)
~~~
{: .language-r}


Within `actel` there is a `preload()` function for folks who are holding their deployment, tagging, and detection data in R variables already instead of the files and folders we saw in the `actel` intro. This function expects 4 input objects, plus the 'spatial' data object that will help us describe the locations of our receivers and how the animals are allowed to move between them.

To achieve the minimum required data for `actel`'s ingestion, we'll want deployment and recovery datetimes, instrument models, etc. We can transform our metadata's standard format into the standard format and naming schemes expected by `actel::preload()` with a bit of dplyr magic:

~~~
# Load the ACT metadata and detection extracts -------------
# set working directory to the data folder for this workshop
setwd("YOUR/PATH/TO/data/act")

# Our project's detections file - I'll use readr to read everything from proj59 in at once:

proj_dets <- list.files(pattern="proj59_matched_detections*") %>% 
  map_df(~readr::read_csv(.))
# note: readr::read_csv will read in csvs inside zip files no problem.

# read in the tag metadata:

tag_metadata <- readxl::read_excel('Tag_Metadata/Proj59_Metadata_bluecatfish.xls', 
                                   sheet='Tag Metadata', # use the Tag Metadata sheet from this excel file
                                   skip=4) # skip the first 4 lines as they're 'preamble'


# And we can import first a subset of the deployments in MATOS that were deemed OK to publish
deploy_metadata <- read_csv('act_matos_moorings_receivers_202104130939.csv') %>%
  # Add a very quick and dirty receiver group column.
  mutate(rcvrgroup = ifelse(collectioncode %in% c('PROJ60', 'PROJ61'), # if we're talking PROJ61
                            paste0(collectioncode,station_name), #let my receiver group be the station name
                            collectioncode)) # for other project receivers just make it their whole project code.

# Also tried to figure out if there was a pattern to station naming that we could take advantage of
# but nothing obvious materialized.
# mutate(rcvrgroup = paste(collectioncode, stringr::str_replace_all(station_name, "[:digit:]", ""), sep='_'))

# Let's review the groups quickly to see if we under or over-shot what our receiver groups should be.
# nb. hiding the legend because there are too many categories.

deploy_metadata %>% ggplot(aes(deploy_lat, deploy_long, colour=rcvrgroup)) + 
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

# Create a station entry from the projectcode and station number.
# --- add station to receiver metadata ----
full_receiver_meta <- all_stations %>%
  dplyr::mutate(
    station = paste(collectioncode, station_name, sep = '-')
  ) %>% 
  filter(is.na(rcvrstatus)|rcvrstatus != 'lost')
~~~
{: .language-r}

 We've now imported our data, and renamed a few columns from the receiver metadata sheet so that they are in a nicer format. We also create a few helper columns, like a 'station' column that is of the form `collectioncode` + `station_name`, guaranteed unique for any project across the entire Network.

### Formatting - Tagging and Deployment Data

As we saw earlier, tagging metadata is entered into `Actel` as `biometrics`, and deployment metadata as `deployments`. These data structures also require a few specially named columns, and a properly formatted date.
~~~
# All dates will be supplied to Actel in this format:
actel_datefmt = '%Y-%m-%d %H:%M:%S'

# biometrics is the tag metadata. If you have a tag metadata sheet, it looks like this:

actel_biometrics <- tag_metadata %>% dplyr::mutate(Release.date = format(UTC_RELEASE_DATE_TIME, actel_datefmt),
                                                   Signal=as.integer(TAG_ID_CODE),
                                                   Release.site = RELEASE_LOCATION, 
                                                   # Group=RELEASE_LOCATION  # can supply group to subdivide tagging groups
)


# deployments is based in the receiver deployment metadata sheet

actel_deployments <- full_receiver_meta %>% dplyr::filter(!is.na(recovery_date)) %>%
  mutate(Station.name = station,
         Start = format(deploy_date, actel_datefmt), # no time data for these deployments
         Stop = format(recovery_date, actel_datefmt),  # not uncommon for this region
         Receiver = rcvrserial) %>%
  arrange(Receiver, Start)

~~~
{: .language-r}

### Detections

For detections, a few columns need to exist: `Transmitter` holds the full transmitter ID. `Receiver` holds the receiver serial number, `Timestamp` has the detection times, and we use a couple of `Actel` functions to split `CodeSpace` and `Signal` from the full `transmitter_id`.

~~~
# Renaming some columns in the Detection extract files   
actel_dets <- proj_dets %>% dplyr::filter(receiver != 'release') %>%
  dplyr::mutate(Transmitter = tagname,
                Receiver = as.integer(receiver),
                Timestamp = format(datecollected, actel_datefmt),
                CodeSpace = extractCodeSpaces(tagname),
                Signal = extractSignals(tagname), 
                Sensor.Value = sensorvalue,
                Sensor.Unit = sensorunit)
~~~
{: .language-r}

Note: we don't have any environmental data in our detection extract here, but `Actel` will also find and plot temperature or other sensor values if you have those kinds of tags.

### Creating the Spatial dataframe

The `spatial` dataframe must have entries for all release locations and all receiver deployment locations. Basically, it must have an entry for every distinct location we can say we know an animal has been.
~~~
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
~~~
{: .language-r}

Now, for longer data series, we may have similar stations that were deployed and redeployed at very slightly different locations. One way to deal with this issue is that for stations that are named the same, we assign an average location in `spatial`.

Another way we might overcome this issue could be to increment station_names that are repeated and provide their distinct locations.

~~~
# group by station name and take the mean lat and lon of each station deployment history.
actel_spatial_sum <- actel_spatial %>% dplyr::group_by(Station.name, Type) %>%
  dplyr::summarize(Latitude = mean(Latitude),
                   Longitude = mean(Longitude),
                   Array =  first(Array))

~~~
{: .language-r}


### Creating the Actel data object w/ `preload()`

Now you have everything you need to call `preload()`.

~~~
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
# resorting to this one
~~~
{: .language-r}

There will very likely be some issues with the data that the `Actel` checkers find and warn us about. Detections outside the deployment time bounds, receivers that aren't in your metadata. For the purposes of today, we will drop those rows from the final copy of the data, but you can take these prompts as cues to verify your input metadata is accurate and complete. It is up to you in the end to determine whether there is a problem with the data, or an overzealous check that you can safely ignore. Here our demo is using a very deeply subsetted version of one project's data, and it's not surprising to be missing some deployments.

Once you have an `Actel` object, you can run `explore()` to generate your project's summary reports:
~~~
# actel::explore()

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

~~~
{: .language-r}


Review the file that `Actel` pops up in our browser. It presumed our Arrays were arranged linearly and alphabetically, which is of course not correct! 


### Custom spatial.txt files for Actel

We'll have to tell `Actel` how our arrays are inter-connected. To do this, we'll need to design a spatial.txt file for our detection data.

To help with this, we can go back and visualize our study area interactively, and start to see how the Arrays are connected.

~~~
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

~~~
{: .language-r}

Can we design a graph and write it into spatial.txt that fits all these Arrays together? The station value we put in Array for our PROJ61 and PROJ60 projects looks to be a bit too granular for our purposes. Maybe we can combine many arrays that are co-located in open water into a singular 'zone', preserving the complexity of the river systems but creating a large basin to which we can connect the furthest downstream of those river arrays.

To do this, we only need to update the arrays in our spatial.csv file or `actel_spatial` dataframe. We don't need to edit our source metadata! We will have to define a spatial.txt file and how these newly defined Arrays interconnect. While there won't be time to do that for this example dataset and its large and very complicated region, this approach is definitely suitable for small river systems and even perhaps for multiple river systems feeding a bay and onward to the open water. If you'd like to apply `Actel` to your data and want to define a custom spatial.txt file, there are some code examples included in `code/day2/5_actel_custom_spatial.R` that might be helpful to get you started.

## MIGRAMAR Node

### Preparing our data to use in Actel

So now, as the last piece of stock curriculum for this workshop, let's quickly look at how we can take the data reports we get from the MigraMar (or any other OTN-compatible data partner, like FACT, or OTN proper) and make it ready for `Actel`.

~~~
# Using MigraMar-style data in Actel ####

library(actel)
library(stringr)
library(glatos)
library(tidyverse)
library(readxl)
~~~
{: .language-r}


Within `actel` there is a `preload()` function for folks who are holding their deployment, tagging, and detection data in R variables already instead of the files and folders we saw in the `actel` intro. This function expects 4 input objects, plus the 'spatial' data object that will help us describe the locations of our receivers and how the animals are allowed to move between them.

To achieve the minimum required data for `actel`'s ingestion, we'll want deployment and recovery datetimes, instrument models, etc. We can transform our metadata's standard format into the standard format and naming schemes expected by `actel::preload()` with a bit of dplyr magic:

~~~
# Load the MigraMar metadata and detection extracts -------------
# set working directory to the data folder for this workshop
setwd("YOUR/PATH/TO/data/migramar")

# Our project's detections file - I'll use readr to read everything from gmr in at once:

proj_dets <- list.files(pattern="gmr_matched_detections*") %>% 
  map_df(~readr::read_csv(.))
# note: readr::read_csv will read in csvs inside zip files no problem.

# read in the tag metadata:

tag_metadata <- readxl::read_excel('gmr_tagging_metadata.xls', 
                                   sheet='Tag Metadata'# use the Tag Metadata sheet from this excel file
                                   ) # skip the first 4 lines as they're 'preamble'


# And we can import our gmr deployment metadata
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

# Create a station entry from the projectcode and station number.
# --- add station to receiver metadata ----
full_receiver_meta <- deploy_metadata %>%
  dplyr::mutate(
    station = paste(OTN_ARRAY, STATION_NO, sep = '-')
  ) %>% 
  filter(is.na(`RECOVERED (y/n/l)`)|`RECOVERED (y/n/l)` != 'lost')
~~~
{: .language-r}

We've now imported our data, and renamed a few columns from the receiver metadata sheet so that they are in a nicer format. We also create a few helper columns, like a 'station' column that is of the form `collectioncode` + `station_name`, guaranteed unique for any project across the entire Network.

### Formatting - Tagging and Deployment Data

As we saw earlier, tagging metadata is entered into `Actel` as `biometrics`, and deployment metadata as `deployments`. These data structures also require a few specially named columns, and a properly formatted date.
~~~
# All dates will be supplied to Actel in this format:
actel_datefmt = '%Y-%m-%d %H:%M:%S'

# biometrics is the tag metadata. If you have a tag metadata sheet, it looks like this:

ctel_biometrics <- tag_metadata %>% dplyr::mutate(Release.date = format(as.POSIXct(UTC_RELEASE_DATE_TIME), actel_datefmt),
                                                   Signal=as.integer(TAG_ID_CODE),
                                                   Release.site = `RELEASE_LOCATION (SITIO DE MARCAJE)`, 
                                                   # Group=RELEASE_LOCATION  # can supply group to subdivide tagging groups
)


# deployments is based in the receiver deployment metadata sheet

actel_deployments <- full_receiver_meta %>% dplyr::filter(!is.na(`RECOVER_DATE_TIME (yyyy-mm-ddThh:mm:ss)`)) %>%
  mutate(Station.name = station,
         Start = format(as.POSIXct(`DEPLOY_DATE_TIME   (yyyy-mm-ddThh:mm:ss)`), actel_datefmt), # no time data for these deployments
         Stop = format(as.POSIXct(`RECOVER_DATE_TIME (yyyy-mm-ddThh:mm:ss)`), actel_datefmt),  # not uncommon for this region
         Receiver = INS_SERIAL_NO) %>%
  arrange(Receiver, Start)

~~~
{: .language-r}

### Detections

For detections, a few columns need to exist: `Transmitter` holds the full transmitter ID. `Receiver` holds the receiver serial number, `Timestamp` has the detection times, and we use a couple of `Actel` functions to split `CodeSpace` and `Signal` from the full `transmitter_id`.

~~~
# Renaming some columns in the Detection extract files   
actel_dets <- proj_dets %>% dplyr::filter(receiver != 'release') %>%
  dplyr::mutate(Transmitter = tagname,
                Receiver = as.integer(receiver),
                Timestamp = format(datecollected, actel_datefmt),
                CodeSpace = extractCodeSpaces(tagname),
                Signal = extractSignals(tagname), 
                Sensor.Value = sensorvalue,
                Sensor.Unit = sensorunit)
~~~
{: .language-r}

Note: we don't have any environmental data in our detection extract here, but `Actel` will also find and plot temperature or other sensor values if you have those kinds of tags.

### Creating the Spatial dataframe

The `spatial` dataframe must have entries for all release locations and all receiver deployment locations. Basically, it must have an entry for every distinct location we can say we know an animal has been.
~~~
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
~~~
{: .language-r}

Now, for longer data series, we may have similar stations that were deployed and redeployed at very slightly different locations. One way to deal with this issue is that for stations that are named the same, we assign an average location in `spatial`.

Another way we might overcome this issue could be to increment station_names that are repeated and provide their distinct locations.

~~~
# group by station name and take the mean lat and lon of each station deployment history.
actel_spatial_sum <- actel_spatial %>% dplyr::group_by(Station.name, Type) %>%
  dplyr::summarize(Latitude = mean(Latitude),
                   Longitude = mean(Longitude),
                   Array =  first(Array))
~~~
{: .language-r}


### Creating the Actel data object w/ `preload()`

Now you have everything you need to call `preload()`.

~~~
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
# resorting to this one
~~~
{: .language-r}

There will very likely be some issues with the data that the `Actel` checkers find and warn us about. Detections outside the deployment time bounds, receivers that aren't in your metadata. For the purposes of today, we will drop those rows from the final copy of the data, but you can take these prompts as cues to verify your input metadata is accurate and complete. It is up to you in the end to determine whether there is a problem with the data, or an overzealous check that you can safely ignore. Here our demo is using a very deeply subsetted version of one project's data, and it's not surprising to be missing some deployments.

Once you have an `Actel` object, you can run `explore()` to generate your project's summary reports:
~~~
# actel::explore()

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

~~~
{: .language-r}


Review the file that `Actel` pops up in our browser. It presumed our Arrays were arranged linearly and alphabetically, which is of course not correct! 


### Custom spatial.txt files for Actel

We'll have to tell `Actel` how our arrays are inter-connected. To do this, we'll need to design a spatial.txt file for our detection data.

To help with this, we can go back and visualize our study area interactively, and start to see how the Arrays are connected.

~~~
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

~~~
{: .language-r}

Can we design a graph and write it into spatial.txt that fits all these Arrays together? The station value we put in Array for our PROJ61 and PROJ60 projects looks to be a bit too granular for our purposes. Maybe we can combine many arrays that are co-located in open water into a singular 'zone', preserving the complexity of the river systems but creating a large basin to which we can connect the furthest downstream of those river arrays.

To do this, we only need to update the arrays in our spatial.csv file or `actel_spatial` dataframe. We don't need to edit our source metadata! We will have to define a spatial.txt file and how these newly defined Arrays interconnect. While there won't be time to do that for this example dataset and its large and very complicated region, this approach is definitely suitable for small river systems and even perhaps for multiple river systems feeding a bay and onward to the open water. If you'd like to apply `Actel` to your data and want to define a custom spatial.txt file we can help you get started.
