## Set your working directory ####

setwd("./data/")  
library(glatos)
library(tidyverse)
library(VTrack)
# Get file path to example FACT data
det_file_name <- 'tqcs_matched_detections.csv'

## GLATOS help files are helpful!! ####
?read_otn_detections

# Save our detections file data into a dataframe called detections
detections <- read_otn_detections(det_file=det_file_name)

# Detection extracts have rows that report the animal release 
# for all the animals in the file:

View(detections %>% filter(receiver_sn == "release") %>% dplyr::select(transmitter_id, receiver_sn, detection_timestamp_utc, notes))

# Remove these rows from our dataset, leaving just acoustic detection data:
detections <- detections %>% filter(receiver_sn != "release")

# Don't have to use View, can quickly look at first 2 rows of output
head(detections, 2)

## Filtering False Detections ####
## ?glatos::false_detections

# write the filtered data (no rows deleted, just a filter column added)
# to a new det_filtered object
detections_filtered <- false_detections(detections, tf=3600, show_plot=TRUE)
head(detections_filtered)
nrow(detections_filtered)


# Filter based on the column if you're happy with it.
detections_filtered <- detections_filtered[detections_filtered$passed_filter == 1,]
nrow(detections_filtered) # Smaller than before


# Summarize Detections ####

# By animal ====
sum_animal <- summarize_detections(detections_filtered, location_col = 'station', summ_type='animal')

sum_animal


# By location ====

sum_location <- summarize_detections(detections_filtered, location_col = 'station', summ_type='location')

head(sum_location)


# By both dimensions
sum_animal_location <- summarize_detections(det = detections_filtered,
                                            location_col = 'station',
                                            summ_type='both')

sum_animal_location


# Filter out stations where the animal was NOT detected.
sum_animal_location <- sum_animal_location %>% filter(num_dets > 0)

sum_animal_location


# Create a custom vector of Animal IDs to pass to the summary function
# look only for these ids when doing your summary
tagged_fish <- c("TQCS-1049258-2008-02-14", "TQCS-1055546-2008-04-30", "TQCS-1064459-2009-06-29")

sum_animal_custom <- summarize_detections(det=detections_filtered,
                                          animals=tagged_fish,  # Supply the vector to the function
                                          location_col = 'station',
                                          summ_type='animal')

sum_animal_custom


# Reduce Detections to Detection Events ####

# ?glatos::detection_events
# arrival and departure time instead of multiple detection rows
# you specify how long an animal must be absent before starting a fresh event

events <- detection_events(detections_filtered,
                           location_col = 'station', # combines events across different receivers in a single array
                           time_sep=432000)

head(events)


# keep detections, but add a 'group' column for each event group
detections_w_events <- detection_events(detections_filtered,
                                        location_col = 'station', # combines events across different receivers in a single array
                                        time_sep=432000, condense=FALSE)

?residence_index

# Calc residence index using the Kessel method
rik_data <- glatos::residence_index(events, 
                                    calculation_method = 'kessel')
rik_data

# Calc residence index using the time interval method, interval set to 6 hours
rit_data <- glatos::residence_index(events, 
                                    calculation_method = 'time_interval', 
                                    time_interval_size = "6 hours")
rit_data

# Converting FACT/OTN/GLATOS-style dataframes to ATT format for use with VTrack ####

?convert_otn_to_att

# OTN's tagging metadata sheet
tag_sheet_path <- 'TQCS_metadata_tagging.xlsx'
rcvr_sheet_path <- 'TEQ_Deployments.xlsx'

# Load the data from the tagging sheet and the receiver sheet
tags <- prepare_tag_sheet(tag_sheet_path, sheet=2)
receivers <- prepare_deploy_sheet(rcvr_sheet_path)

# Add columns missing from FACT extracts
detections_filtered['sensorvalue'] = NA
detections_filtered['sensorunit'] = NA

# Rename the station names in receivers to match station names in detections
receivers <- receivers %>% mutate(station=substring(station, 4))

ATTdata <- convert_otn_to_att(detections_filtered, tags, deploymentSheet = receivers)

ATTdata$Tag.Detections
ATTdata$Tag.Metadata
ATTdata$Station.Information


# If you're going to do spatial things in ATT:
library(rgdal)
# Tell the ATT dataframe its coordinates are in decimal lat/lon
proj <- CRS("+init=epsg:4326")
attr(ATTdata, "CRS") <-proj

# Now that we have an ATT dataframe, we can use it in VTrack functions:

# Abacus plot:
VTrack::abacusPlot(ATTdata)


# Calculate centers of activity
?COA
coa <- VTrack::COA(ATTdata)
View(coa)


# Bubble Plots #### 

library(raster)
library(sp)
USA <- getData('GADM', country="USA", level=1)
FL <- USA[USA$NAME_1=="Florida",]



# Bubble Plots for Spatial Distribution of Fish ####
# bubble variable gets the summary data that was created to make the plot
detections_filtered
bubble <- detection_bubble_plot(detections_filtered,
                                location_col = 'station',
                                map = FL,
                                col_grad=c('white', 'green'),
                                background_xlim = c(-81, -80),
                                background_ylim = c(26, 28))





# Using FACT/OTN/GLATOS-style data in Actel ####

# install.packages('actel')  # CRAN Version 1.2.0

# Or the development version:
# remotes::install_github("hugomflavio/actel", build_opts = c("--no-resave-data", "--no-manual"), build_vignettes = TRUE)

library(actel)
library(stringr)

# Hugo has created a preload() function that expects 4 objects, similar to VTrack's 3 objects

# But it wants a bit more data, so we're going to go back to our deployment metadata sheet and reload it:
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



# dates will be supplied in this format:
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
  
# Renaming some columns in the Detection extract files   
actel_dets <- detections %>% mutate(Transmitter = transmitter_id,
                                   Receiver = as.integer(receiver_sn),
                                   Timestamp = format(detection_timestamp_utc, actel_datefmt), 
                                   CodeSpace = extractCodeSpaces(transmitter_id),
                                   Signal = extractSignals(transmitter_id))
  
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

actel_spatial_sum <- actel_spatial %>% group_by(Station.name, Type) %>% dplyr::summarize(Latitude = mean(Latitude), 
                                                                                         Longitude = mean(Longitude),
                                                                                         Array =  first(Array))
# and a timezone

tz <- "GMT0"

# Then you can create the Actel Project object.
actel_project <- preload(biometrics = actel_biometrics, 
                         spatial = actel_spatial_sum, 
                         deployments = actel_deployments, 
                         detections = actel_dets, 
                         tz = tz)

# Once you have an Actel object, you can run things like explore:

actel_explore_output <- explore(actel_project, tz=tz, report=TRUE, print.releases=FALSE)


# See more on what to do with this output in Hugo's talk