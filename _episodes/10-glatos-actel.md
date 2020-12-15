---
title: Preparing FACT/OTN/GLATOS Data for actel
teaching: 15
exercises: 0
questions:
    - "How do I take my `glatos` data and format for actel?"
---
### Preparing our data to use in Actel

Up next, we're going to be learning about Actel, a new player in the acoustic telemetry data analysis ecosystem. We've got the package author coming up next to tell you all about it, so let's quickly look at how we can take the data we have been working with from FACT (and any OTN/GLATOS style data) and make it ready for Actel.

~~~
# Using FACT/OTN/GLATOS-style data in Actel ####

library(actel)
library(stringr)

# Actel now contains a preload() function that is very useful for folks who are getting detection extracts from one of the major networks, or otherwise are holding their deployment, tagging, and detection data in R variables already. This function expects 4 input objects, similar to VTrack's 3 objects, plus a 'spatial' data object that will help us describe the places we are able to detect animals and how the animals are allowed to move between them.

# But it wants a bit more data than VTrack did, so we're going to have to go back to our deployment metadata sheet and reload it:
full_receiver_meta <- readxl::read_excel(rcvr_sheet_path, sheet=1, skip=0) %>% 
                      dplyr::rename(
                                deploy_lat = DEPLOY_LAT,
                                deploy_long = DEPLOY_LONG,
                                ins_model_no = INS_MODEL_NO,
                                deploy_date_time = `DEPLOY_DATE_TIME   (yyyy-mm-ddThh:mm:ss)`,
                                recover_date_time = `RECOVER_DATE_TIME (yyyy-mm-ddThh:mm:ss)`,
                              ) %>%
                      dplyr::mutate(
                                station = paste(OTN_ARRAY, STATION_NO, sep = '')
                      )
~~~
{: .language-r}

 We rename a few columns from the receiver metadata sheet so that they are in a nicer format. We also create a 'station' column that is array_code + station_name, guaranteed unique for any project across the entire Network.

### Formatting - Tagging and Deployment Data

Tagging metadata is entered into Actel as `biometrics`, and deployment metadata as `deployments`. It needs a few specially named columns, and a properly formatted date.
~~~


# All dates will be supplied to Actel in this format:
actel_datefmt = '%Y-%m-%d %H:%M:%S'

# biometrics is the tag metadata. If you have a tag metadata sheet, it looks like this:
actel_biometrics <- tags %>% mutate(Release.date = format(time, actel_datefmt), 
                         Signal=as.integer(TAG_ID_CODE),
                         Release.site = RELEASE_LOCATION)
  
# deployments is based in the receiver deployment metadata sheet
actel_deployments <- full_receiver_meta %>% filter(!is.na(recover_date_time)) %>%
                                   mutate(Station.name = station, 
                                   Start = format(deploy_date_time, actel_datefmt), # no time data for these deployments
                                   Stop = format(recover_date_time, actel_datefmt),  # not uncommon for this region
                                   Receiver = INS_SERIAL_NO) %>% 
                                   arrange(Receiver, Start)

~~~
{: .language-r}

### Detections

For detections, a few columns need to exist: `Transmitter` holds the full transmitter ID. `Receiver` holds the receiver serial number, `Timestamp` has the detection times, and we use a couple of Actel functions to split `CodeSpace` and `Signal` from the full `transmitter_id`.

~~~
# Renaming some columns in the Detection extract files   
actel_dets <- detections %>% mutate(Transmitter = transmitter_id,
                                   Receiver = as.integer(receiver_sn),
                                   Timestamp = format(detection_timestamp_utc, actel_datefmt), 
                                   CodeSpace = extractCodeSpaces(transmitter_id),
                                   Signal = extractSignals(transmitter_id))
~~~
{: .language-r}

### Creating the Spatial dataframe


~~~
# Spatial is all release locations and all receiver deployment locations. 
  # Basically, every distinct location we can say we know an animal has been.
actel_receivers <- full_receiver_meta %>% mutate( Station.name = station, 
                                        Latitude = deploy_lat, 
                                        Longitude = deploy_long,
                                        Type='Hydrophone') %>% 
                                        mutate(Array=OTN_ARRAY) %>%    # Having this many distinct arrays breaks things with few clues as to why.
                                        dplyr::select(Station.name, Latitude, Longitude, Array, Type) %>% 
                                        distinct(Station.name, Latitude, Longitude, Array, Type)
  
actel_tag_releases <- tags %>% mutate(Station.name = RELEASE_LOCATION,
                                      Latitude = latitude,
                                      Longitude = longitude,
                                      Type='Release') %>% 
                                      mutate(Array = 'TEQ') %>% # released by TEQ, TEQ is 'first array'
                                      distinct(Station.name, Latitude, Longitude, Array, Type)

# Bind the releases and the deployments together for the unique set of spatial locations
actel_spatial <- actel_receivers %>% bind_rows(actel_tag_releases)

# Now, for stations that are named the same, take an average location.

actel_spatial_sum <- actel_spatial %>% group_by(Station.name, Type) %>%
                                       dplyr::summarize(Latitude = mean(Latitude), 
                                                        Longitude = mean(Longitude),
                                                        Array =  first(Array))

~~~
{: .language-r}


### Creating the Actel data object w/ `preload()`

Now you have everything you need to call `preload()`. 

~~~
# Specify the timezone that your timestamps are in. 
# OTN provides them in GMT. 
# FACT has both UTC/GMT and Eastern

tz <- "GMT0"

# Then you can create the Actel project object.
actel_project <- preload(biometrics = actel_biometrics, 
                         spatial = actel_spatial_sum, 
                         deployments = actel_deployments, 
                         detections = actel_dets, 
                         tz = tz)
~~~
{: .language-r}

There will be some issues with the data that the Actel checkers find. Detections outside the deployment time bounds, receivers that aren't in your metadata. For the purposes of today, we will drop those rows from the final copy of the data, but you can take these prompts as cues to verify your input metadata is accurate and complete.

~~~
# Once you have an Actel object, you can run things like explore to generate the summary reports you're about to see:
actel_explore_output <- explore(actel_project, tz=tz, report=TRUE, print.releases=FALSE)

~~~
{: .language-r}

See more on what you can do with this output coming up next!

