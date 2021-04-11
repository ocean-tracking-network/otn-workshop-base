# 07 - Introduction to GLATOS ####

## Set your working directory

setwd("./data/")  
library(glatos)
library(tidyverse)
library(VTrack)

# First we need to create a one detections files from all our detection extracts.
library(utils)

unzip('ACT Network workshop datasets.zip', exdir = "act-data")

for (zipfile in list.files('act-data', pattern = '\\.zip', full.names = TRUE)) {
  unzip(zipfile, exdir = 'act-data/dets')
  file.remove(zipfile)
}

all_dets <- tibble()
for (detfile in list.files('act-data/dets', full.names = TRUE)) {
  dets <- read.csv(detfile)
  all_dets <- bind_rows(all_dets, dets)
}  
write.csv(all_dets, "act-data/all_dets.csv", append = FALSE)

## GLATOS help files are helpful!!
?read_otn_deployments

# Save our detections file data into a dataframe called detections
detections <- read_otn_detections('act-data/all_dets.csv')


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
# ?summarize_detections
# summarize_detections(detections_filtered)

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

head(sum_animal_location)


# Filter out stations where the animal was NOT detected.
sum_animal_location <- sum_animal_location %>% filter(num_dets > 0)

sum_animal_location


# Create a custom vector of Animal IDs to pass to the summary function
# look only for these ids when doing your summary
tagged_fish <- c('PROJ58-1218508-2015-10-13', 'PROJ58-1218510-2015-10-13')

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
                           time_sep=3600)

head(events)


# keep detections, but add a 'group' column for each event group
detections_w_events <- detection_events(detections_filtered,
                                        location_col = 'station', # combines events across different receivers in a single array
                                        time_sep=3600, condense=FALSE)

# 08 - More Features of glatos ####


?residence_index

#Using all the events data will take too long, we will subset to just use a couple animals
events %>% group_by(animal_id) %>% summarise(count=n()) %>% arrange(desc(count))

subset_animals <- c('PROJ59-1191631-2014-07-09', 'PROJ59-1191628-2014-07-07', 'PROJ64-1218527-2016-06-07')
events_subset <- events %>% filter(animal_id %in% subset_animals)

# Calc residence index using the Kessel method
rik_data <- residence_index(events_subset, 
                            calculation_method = 'kessel')
rik_data

# Calc residence index using the time interval method, interval set to 6 hours
rit_data <- residence_index(events_subset, 
                            calculation_method = 'time_interval', 
                            time_interval_size = "6 hours")
rit_data
 
# Converting GLATOS/FACT/OTN-style dataframes to ATT format for use with VTrack ####

?convert_glatos_to_att

# The receiver metadata for the walleye dataset
rec_file <- system.file("extdata", 
                        "sample_receivers.csv", package = "glatos")

receivers <- read_glatos_receivers(rec_file)

tags <- prepare_tag_sheet('act-data/Tag_Metadata/Proj58_Metadata_cownoseray.xls',sheet = 2, start = 5)
tags <- prepare_tag_sheet("/home/ryan/Downloads/Proj58_Metadata_cownoseray.xls", sheet=2, start = 5)

deploys <- read_otn_deployments('act-data/matos_FineToShare_stations_receivers_202104091205.csv')
ATTdata <- convert_otn_to_att(detections_filtered, tags, deploymentObj = deploys)
?read_otn_deployments
# ATT is split into 3 objects, we can view them like this
ATTdata$Tag.Detections
ATTdata$Tag.Metadata
ATTdata$Station.Information

# Now that we have an ATT dataframe, we can use it in VTrack functions:

# Abacus plot:
VTrack::abacusPlot(ATTdata)

# If you're going to do spatial things in ATT:
library(rgdal)
# Tell the ATT dataframe its coordinates are in decimal lat/lon
proj <- CRS("+init=epsg:4326")
attr(ATTdata, "CRS") <-proj


# Calculate centers of activity
?COA
coa <- VTrack::COA(ATTdata)
View(coa)

# Plot a COA
coa153 <- coa %>% filter(Tag.ID == 153)

data(greatLakesPoly) # Get spacial object from glatos package

# plot the object and zoom in to lake Huron. Set colour of water to blue. Add labels to the axises
plot(greatLakesPoly, xlim=c(-85, -82), ylim=c(43, 46), col='blue', xlab="Longitude", ylab="Latitude")

# Create a palette
color <- c(colorRampPalette(c('pink', 'red'))(max(coa153$Number.of.Detections)))

#add the points
points(coa153$Longitude.coa, coa153$Latitude.coa, pch=19, col=color[coa153$Number.of.Detections], 
    cex=log(coa153$Number.of.Stations) + 0.5) # cex is for point size. natural log is for scaling purposes

# add axises and title
axis(1)
axis(2)
title("Centers of Activities for 153")


# Dispersal information
# ?dispersalSummary
dispSum<-dispersalSummary(ATTdata)

View(dispSum)

# Get only the detections when the animal just arrives at a station
dispSum %>% filter(Consecutive.Dispersal > 0) %>%  View

# BREAK 

# 9 - Basic Visualization and Plotting

# Visualizing Data - Abacus Plots ####
# ?glatos::abacus_plot
# customizable version of the standard VUE-derived abacus plots

abacus_plot(detections_w_events, 
            location_col='station', 
            main='Walleye Detection by Station') # can use plot() variables here, they get passed thru to plot()

abacus_plot(detections_w_events, 
            location_col='glatos_array', 
            main='Walleye Detection by Array') 

# pick a single fish to plot
abacus_plot(detections_filtered[detections_filtered$animal_id== "22",],
            location_col='station',
            main="Animal 22 Detections By Station")

# Bubble Plots for Spatial Distribution of Fish ####
# bubble variable gets the summary data that was created to make the plot
detections_filtered

?detection_bubble_plot

bubble_station <- detection_bubble_plot(detections_filtered, 
                                location_col = 'station',
                                out_file = 'walleye_bubbles_by_stations.png')
bubble_station

bubble_array <- detection_bubble_plot(detections_filtered,
                                      out_file = 'walleye_bubbles_by_array.png')
bubble_array


# Challenge 1 ----
# Create a bubble plot of the station in Lake Erie only. Set the bounding box using the provided nw + se cordinates and 
# resize the points. As a bonus, add points for the other receivers in Lake Erie.
# Hint: ?detection_bubble_plot will help a lot
# Here's some code to get you started
erie_arrays <-c("DRF", "DRL", "DRU", "MAU", "RAR", "SCL", "SCM", "TSR") 
nw <- c(43, -83.75) 
se <- c(41.25, -82) 