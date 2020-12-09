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
detections <- detections %>% filter(receiver_sn != "release")
# View first 2 rows of output
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

# Filter out the stations where the animal wasn't detected.
sum_animal_location <- sum_animal_location %>% filter(num_dets > 0)

sum_animal_location
# create a custom vector of Animal IDs to pass to the summary function
# look only for these ids when doing your summary
tagged_fish <- c("TQCS-1049258-2008-02-14", "TQCS-1055546-2008-04-30", "TQCS-1064459-2009-06-29")

sum_animal_custom <- summarize_detections(det=detections_filtered,
                                          animals=tagged_fish,
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

?COA
coa <- VTrack::COA(ATTdata)
View(coa)
