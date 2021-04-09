---
title: Preparing ACT/OTN/GLATOS Data for actel
teaching: 45
exercises: 0
questions:
    - "How do I take my `glatos` data and format for actel?"
---
### Preparing our data to use in Actel

So now, as the last piece of stock curriculum for this workshop, let's quickly look at how we can take the data reports we get from GLATOS (or any other OTN-compatible data partner, like FACT, ACT, or OTN proper) and make it ready for Actel.

~~~
# Using GLATOS-style data in Actel ####

# install.packages('actel')  # CRAN Version 1.2.1

# Or the development version:
# remotes::install_github("hugomflavio/actel", build_opts = c("--no-resave-data", "--no-manual"), build_vignettes = TRUE)

library(actel)
library(stringr)
library(glatos)
library(tidyverse)

~~~
{: .language-r}


Within `actel` there is a `preload()` function for folks who are holding their deployment, tagging, and detection data in R variables already instead of the files and folders we saw in the `actel` intro. This function expects 4 input objects, plus the 'spatial' data object that will help us describe the locations of our receivers and how the animals are allowed to move between them.

To achieve the minimum required data for `actel`'s ingestion, we'll want deployment and recovery datetimes, instrument models, etc. We can transform our metadata's standard format into the standard format and naming schemes expected by `actel::preload()` with a bit of dplyr magic:

~~~
# Load the GLATOS workbook and detections -------------

wb_file <-system.file("extdata", "walleye_workbook.xlsm", package="glatos")

wb_metadata <- glatos::read_glatos_workbook(wb_file)  

# Our project's detections file - I'll use our walleye detections
det_file <- system.file("extdata", "walleye_detections.csv", package = "glatos")

detections <- read_glatos_detections(det_file)

# Let's say we didn't have tag metadata for the walleye.
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

# So now this is our animal tagging metadata
wb_metadata$animals

# and this is our receiver deployment metadata
wb_metadata$receivers

# but our detections are still in this separate spot
det_file <- system.file("extdata", "walleye_detections.csv", package = "glatos")
detections <- read_glatos_detections(det_file)

# Mutate metadata into Actel format ----

# Create a station entry from the glatos array and station number.
# --- add station to receiver metadata ----
full_receiver_meta <- wb_metadata$receivers %>%
  dplyr::mutate(
    station = paste(glatos_array, station_no, sep = '')
  )


~~~
{: .language-r}

 We've now imported our data, and renamed a few columns from the receiver metadata sheet so that they are in a nicer format. We also create a 'station' column that is of the form `array_code` + `station_name`, guaranteed unique for any project across the entire Network.

### Formatting - Tagging and Deployment Data

As we saw earlier, tagging metadata is entered into Actel as `biometrics`, and deployment metadata as `deployments`. These data structures also require a few specially named columns, and a properly formatted date.
~~~
# All dates will be supplied to Actel in this format:
actel_datefmt = '%Y-%m-%d %H:%M:%S'

# biometrics is the tag metadata. If you have a tag metadata sheet, it looks like this:
actel_biometrics <- wb_metadata$animals %>% dplyr::mutate(Release.date = format(utc_release_date_time, actel_datefmt),
                                    Signal=as.integer(tag_id_code),
                                    Release.site = release_location) %>%
  # subset these tag releases to the animals we actually have
  # detections for in our demo dataset
  # Only doing this because the demo dataset is so cut-down, wouldn't make sense
  # to have 500 tags and only 3 of them with detections.
                                    dplyr::filter(animal_id %in% tags$animal_id)


# Actel Deployments ----
# deployments is based in the receiver deployment metadata sheet
actel_deployments <- full_receiver_meta %>% dplyr::filter(!is.na(recover_date_time)) %>%
  mutate(Station.name = station,
         Start = format(deploy_date_time, actel_datefmt), # no time data for these deployments
         Stop = format(recover_date_time, actel_datefmt),  # not uncommon for this region
         Receiver = ins_serial_no) %>%
  arrange(Receiver, Start)

~~~
{: .language-r}

### Detections

For detections, a few columns need to exist: `Transmitter` holds the full transmitter ID. `Receiver` holds the receiver serial number, `Timestamp` has the detection times, and we use a couple of Actel functions to split `CodeSpace` and `Signal` from the full `transmitter_id`.

~~~
# Renaming some columns in the Detection extract files   
actel_dets <- detections %>% dplyr::mutate(Transmitter = transmitter_id,
                                    Receiver = as.integer(receiver_sn),
                                    Timestamp = format(detection_timestamp_utc, actel_datefmt),
                                    CodeSpace = extractCodeSpaces(transmitter_id),
                                    Signal = extractSignals(transmitter_id))
~~~
{: .language-r}

### Creating the Spatial dataframe

The `spatial` dataframe must have entries for all release locations and all receiver deployment locations. Basically, it must have an entry for every distinct location we can say we know an animal has been.
~~~
# Prepare and style entries for receivers
# Prepare and style entries for receivers
actel_receivers <- full_receiver_meta %>% dplyr::mutate( Station.name = station,
                                                  Latitude = deploy_lat,
                                                  Longitude = deploy_long,
                                                  Type='Hydrophone') %>%
  dplyr::mutate(Array=glatos_array) %>%    # Having this many distinct arrays breaks things with few clues as to why.
  dplyr::select(Station.name, Latitude, Longitude, Array, Type) %>%
  distinct(Station.name, Latitude, Longitude, Array, Type)

# Actel Tag Releases ---------------

# Prepare and style entries for tag releases
actel_tag_releases <- wb_metadata$animals %>% mutate(Station.name = release_location,
                                      Latitude = release_latitude,
                                      Longitude = release_longitude,
                                      Type='Release') %>%
  mutate(Array = case_when(Station.name == 'Maumee' ~ 'SIC',
                           Station.name == 'Tittabawassee' ~ 'TTB',
                           Station.name == 'AuGres' ~ 'AGR')) %>% # This value needs to be the nearest array to the release site
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
~~~
{: .language-r}

There will very likely be some issues with the data that the Actel checkers find and warn us about. Detections outside the deployment time bounds, receivers that aren't in your metadata. For the purposes of today, we will drop those rows from the final copy of the data, but you can take these prompts as cues to verify your input metadata is accurate and complete. It is up to you in the end to determine whether there is a problem with the data, or an overzealous check that you can safely ignore. Here our demo is using a very deeply subsetted version of one project's data, and it's not surprising to be missing some deployments.

Once you have an Actel object, you can run `explore()` to generate your project's summary reports:
~~~
# Get summary reports from our dataset:
actel_explore_output <- explore(datapack=actel_project,
                                report=TRUE,
                                print.releases=FALSE)

~~~
{: .language-r}


Review the file that Actel pops up in our browser. It presumed our Arrays were arranged linearly and alphabetically, which is of course not correct! We'll have to tell Actel how our arrays are inter-connected. To do this, we'll need to design a spatial.txt file for our detection data.

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

# and plot it using mapview. The popupTable() function lets us customize our tooltip
mapview(our_receivers %>%    
          select(Longitude, Latitude) %>%           # and get a SpatialPoints object to pass to mapview
          SpatialPoints(CRS('+proj=longlat')),
                    popup = popupTable(our_receivers,
                                       zcol = c("Array",
                                                "Station.name")))  # and make a tooltip we can explore
~~~
{: .language-r}

Can we design a graph and write it into spatial.txt that fits all these Arrays together? The glatos_array value we put in Array looks to be a bit too granular for our purposes. Maybe we can combine many arrays that are co-located in open water into a Lake Huron 'zone', preserving the complexity of the river systems but creating one basin to which we can connect.

To do this, we only need to update the arrays in our spatial.csv file or spatial dataframe.


~~~
# We only need to do this in our spatial.csv file!

huron_arrays <- c('WHT', 'OSC', 'STG', 'PRS', 'FMP',
                  'ORM', 'BMR', 'BBI', 'RND', 'IGN',
                  'MIS', 'TBA')


# Update actel_spatial_sum to reflect the inter-connectivity of the Huron arrays.
actel_spatial_sum_lakes <- actel_spatial_sum %>%
    dplyr::mutate(Array = if_else(Array %in% huron_arrays, 'Huron', #if any of the above, make it 'Huron'
                                       Array)) # else leave it as its current value

# Notice we haven't changed any of our data or metadata, just the spatial table
~~~
{: .language-r}

The spatial.txt file I created is in the data subfolder of the workshop materials, we can use it to define the connectivity between our arrays and the Huron basin.

~~~
spatial_txt_dot = '../../../data/glatos_spatial.txt'  # relative path to this workshop's folder

# How many unique spatial Arrays do we still have, now that we've combined
# so many into Huron?

actel_spatial_sum_lakes %>% dplyr::group_by(Array) %>% dplyr::select(Array) %>% unique()

# OK. let's analyze this dataset with our reduced spatial complexity

actel_project <- preload(biometrics = actel_biometrics,
                         spatial = actel_spatial_sum_lakes,
                         deployments = actel_deployments,
                         detections = actel_dets,
                         dot = readLines(spatial_txt_dot),
                         tz = tz)
~~~
{: .language-r}

now actel understands the connectivity between our arrays better!

~~~
actel_explore_output_lakes <- explore(datapack=actel_project,
                                      report=TRUE,
                                      print.releases=FALSE)

# We no longer get the error about movements skipping/jumping across arrays!
~~~
{: .language-r}
