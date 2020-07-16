## Set your working directory ####

setwd("./code/glatos/")
library(glatos)
# Get file path to example blue shark OTN data
det_file_name <- system.file("extdata", "blue_shark_detections.csv",
                             package = "glatos")

# Receiver Location
rec_file_name <- system.file("extdata", "hfx_deployments.csv",
                             package = "glatos")
## GLATOS help files are helpful!! ####
?read_otn_detections
# Save our detections file data into a dataframe called detections
detections <- read_otn_detections(det_file=det_file_name)
# View first 2 rows of output
head(detections, 2)
?read_otn_deployments
# Save receiver information into receivers dataframe

receivers <- read_otn_deployments(rec_file_name)
head(receivers, 2)
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
sum_animal <- summarize_detections(detections_filtered, summ_type='animal')

sum_animal
# By location ====

sum_location <- summarize_detections(detections_filtered, location_col='glatos_array', summ_type='location')

head(sum_location)
# By both dimensions
sum_animal_location <- summarize_detections(det = detections_filtered,
                                            location_col = 'glatos_array',
                                            summ_type='both')

head(sum_animal_location)
# create a custom vector of Animal IDs to pass to the summary function
# look only for these ids when doing your summary
tagged_fish <- c("NSBS-Alison", "NSBS-Brandy", "NSBS-Hey Jude")

sum_animal_custom <- summarize_detections(det=detections_filtered,
                                          animals=tagged_fish,
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
tag_sheet_path <- system.file("extdata", "otn_nsbs_tag_metadata.xls",
                              package = "glatos")

# Load the data from the tagging sheet
# the 5 means start on line 5, and the 2 means use sheet 2
tags <- prepare_tag_sheet(tag_sheet_path, 5, 2)


ATTdata <- convert_otn_to_att(detections, tags, deploymentObj = receivers)

ATTdata$Tag.Detections
ATTdata$Tag.Metadata
ATTdata$Station.Information

?COA
coa <- VTrack::COA(ATTdata)
View(coa)
