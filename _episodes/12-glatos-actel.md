---
title: Preparing FACT/OTN/GLATOS Data for actel
teaching: 15
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

~~~
{: .language-r}


Within `actel` there is a `preload()` function for folks who are holding their deployment, tagging, and detection data in R variables already instead of the files and folders we saw in the `actel` intro. This function expects 4 input objects, plus the 'spatial' data object that will help us describe the locations of our receivers and how the animals are allowed to move between them.

To achieve the minimum required data for `actel`'s ingestion, we'll want deployment and recovery datetimes, instrument models, etc. We can transform our metadata's standard format into the standard format and naming schemes expected by `actel::preload()` with a bit of dplyr magic:

~~~
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

 We've now renamed a few columns from the receiver metadata sheet so that they are in a nicer format. We also create a 'station' column that is of the form `array_code` + `station_name`, guaranteed unique for any project across the entire Network.

### Formatting - Tagging and Deployment Data

As we saw earlier, tagging metadata is entered into Actel as `biometrics`, and deployment metadata as `deployments`. These data structures also require a few specially named columns, and a properly formatted date.
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

The `spatial` dataframe must have entries for all release locations and all receiver deployment locations. Basically, it must have an entry for every distinct location we can say we know an animal has been.
~~~
# Prepare and style entries for receivers
actel_receivers <- full_receiver_meta %>% mutate( Station.name = station,
                                        Latitude = deploy_lat,
                                        Longitude = deploy_long,
                                        Type='Hydrophone') %>%
                                        mutate(Array=OTN_ARRAY) %>%    # Having this many distinct arrays breaks things with few clues as to why.
                                        dplyr::select(Station.name, Latitude, Longitude, Array, Type) %>%
                                        distinct(Station.name, Latitude, Longitude, Array, Type)

# Prepare and style entries for tag releases
actel_tag_releases <- tags %>% mutate(Station.name = RELEASE_LOCATION,
                                      Latitude = latitude,
                                      Longitude = longitude,
                                      Type='Release') %>%
                                      mutate(Array = 'TEQ') %>% # released by TEQ, TEQ is 'first array'
                                      distinct(Station.name, Latitude, Longitude, Array, Type)

# Bind the releases and the deployments together for the unique set of spatial locations
actel_spatial <- actel_receivers %>% bind_rows(actel_tag_releases)
~~~
{: .language-r}

Now, for longer data series, we may have similar stations that were deployed and redeployed at very slightly different locations. One way to deal with this issue is that for stations that are named the same, we assign an average location in `spatial`.

Another way we might overcome this issue could be to increment station_names that are repeated and provide their distinct locations.

~~~
# group by station name and take the mean lat and lon of each station deployment history.
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
# GLATOS has

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

There will very likely be some issues with the data that the Actel checkers find and warn us about. Detections outside the deployment time bounds, receivers that aren't in your metadata. For the purposes of today, we will drop those rows from the final copy of the data, but you can take these prompts as cues to verify your input metadata is accurate and complete. It is up to you in the end to determine whether there is a problem with the data, or an overzealous check that you can safely ignore.

Once you have an Actel object, you can run `explore()` to generate your project's summary reports:
~~~
# Get summary reports from our dataset:
actel_explore_output <- explore(actel_project, tz=tz, report=TRUE, print.releases=FALSE)

~~~
{: .language-r}

