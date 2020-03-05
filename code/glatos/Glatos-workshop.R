# GLATOS Intro Workshop ----
## Set your working directory ####

setwd("~/code/glatos-2020/")
library(glatos)

# Get file path to example walleye GLATOS exports
# Detection Data
det_file <- system.file("extdata", "walleye_detections.csv", package = "glatos")

# Receiver Location
rec_file <- system.file("extdata", "sample_receivers.csv", package = "glatos")

# Load Project Workbook
wb_file <- system.file("extdata", "walleye_workbook.xlsm", package = "glatos")

## GLATOS help files are helpful!! ####
?read_glatos_detections

# Save our detections file data into a dataframe called detections
detections <- read_glatos_detections(det_file=det_file)

# View first 2 rows of output
head(detections, 2)

?read_glatos_receivers
# Save receiver information into receivers dataframe

receivers <- read_glatos_receivers(rec_file)
head(receivers, 2)

workbook <- read_glatos_workbook(wb_file)
head(workbook)

# GLATOS data types ####
class(workbook)  # Workbook is a workbook, and a list

names(workbook)  # Contains metadata, animals, receivers

# access the internals
class(workbook$metadata) # wait, still a list?
class(workbook$animals) 
class(workbook[['receivers']])


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
# 


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
tagged_fish <- c("153", "22", "23", "14", "221")

sum_animal_custom <- summarize_detections(det=detections_filtered,
                                          animals=tagged_fish,
                                          summ_type='animal')

sum_animal_custom


# Reduce Detections to Detection Events ####

# ?glatos::detection_events
# arrival and departure time instead of multiple detection rows
# you specify how long an animal must be absent before starting a fresh event

events <- detection_events(detections_filtered, 
                           location_col = 'glatos_array', # combines events across different receivers in a single array
                           time_sep=432000)

head(events)

# keep detections, but add a 'group' column for each event group
detections_w_events <- detection_events(detections_filtered, 
                           location_col = 'glatos_array', # combines events across different receivers in a single array
                           time_sep=432000, condense=FALSE)

# Visualizing Data - Abacus Plots ####
# ?glatos::abacus_plot
# customizable version of the standard VUE-derived abacus plots

abacus_plot(detections_w_events, 
            location_col='glatos_array', 
            main='TITLE OF PLOT') # can use plot() variables here, they get passed thru to plot()

# pick a single fish to plot
abacus_plot(detections_filtered[detections_filtered$animal_id== "153",])



# subset of receivers?

receivers_subset <- receivers[receivers$glatos_project=='HECWL',]

det_first <- min(detections$detection_timestamp_utc)
det_last <- max(detections$detection_timestamp_utc)
receivers_subset <- receivers_subset[
                        receivers_subset$deploy_date_time < det_last &
                        receivers_subset$recover_date_time > det_first &
                        !is.na(receivers_subset$recover_date_time),] #removes deployments without recoveries

locs <- unique(receivers_subset$glatos_array)

locs

# Abacus Plots w/ Receiver History ####
# Using the receiver data frame from the start:
# See the receiver history behind the detections to know what you could see.
abacus_plot(detections_filtered[detections_filtered$animal_id == '153',],
            pch = 16,
            type='b',
            locations = sort(locs, decreasing = TRUE),
            receiver_history=receivers)

# Bubble Plots for Spatial Distribution of Fish ####
# bubble variable gets the summary data that was created to make the plot
bubble <- detection_bubble_plot(detections_filtered, 
                      location_col = 'glatos_array',
                      col_grad=c('white', 'green'))

# more complex example including zeroes by adding a specific
# receiver locations dataset, in this case the receivers dataset above.

bubble_custom <- detection_bubble_plot(detections_filtered,
                                       location_col='glatos_array',
                                       background_xlim=c(-85, -80),
                                       background_ylim=c(42.7, 46.38),
                                       symbol_radius = 2,
                                       receiver_locs = receivers)



# Animations ####

# ?interpolate_path

# Supply an optional transition layer, built in make_transition.

library(sp) #for loading greatLakesPoly
library(raster) #for raster manipulation (e.g., crop)

# get example walleye detection data ####
det_file <- system.file("extdata", "walleye_detections.csv",
                        package = "glatos")
det <- read_glatos_detections(det_file)

# take a look
head(det)

# extract one fish and subset date ####
det <- det[det$animal_id == 22 & 
             det$detection_timestamp_utc > as.POSIXct("2012-04-08") &
             det$detection_timestamp_utc < as.POSIXct("2013-04-15") , ]

# get polygon of the Great Lakes  ####
data(greatLakesPoly) #glatos example data; a SpatialPolygonsDataFrame

# crop polygon to western Lake Erie ####
maumee <-  crop(greatLakesPoly, extent(-83.7, -82.5, 41.3, 42.4))
plot(maumee, col = "grey")
points(deploy_lat ~ deploy_long, data = det, pch = 20, col = "red", 
       xlim = c(-83.7, -80))

#make transition layer object ####
# Note: using make_transition2 here for simplicity, but 
#       make_transition is generally preferred for real application  
#       if your system can run it see ?make_transition
tran <- make_transition(maumee, res = c(0.1, 0.1))

plot(tran$rast, xlim = c(-83.7, -82.0), ylim = c(41.3, 42.7))
plot(maumee, add = TRUE)

# not high enough resolution- bump up resolution
tran1 <- make_transition(maumee, res = c(0.001, 0.001))

# plot to check resolution- much better
plot(tran1$rast, xlim = c(-83.7, -82.0), ylim = c(41.3, 42.7))
plot(maumee, add = TRUE)


# add fish detections to make sure they are "on the map"
# plot unique values only for simplicity
foo <- unique(det[, c("deploy_lat", "deploy_long")]) 
points(foo$deploy_long, foo$deploy_lat, pch = 20, col = "red")

# call with "transition matrix" (non-linear interpolation), other options ####
# note that it is quite a bit slower due than linear interpolation
pos2 <- interpolate_path(det, trans = tran1$transition, out_class = "data.table")

plot(maumee, col = "grey")
points(latitude ~ longitude, data = pos2, pch=20, col='red', cex=0.5)

# Make frames out of the data points ####
# ?make_frames

# just gimme the animation!
setwd('~/code/glatos-2020')
frameset <- make_frames(pos2)

# can set animate = FALSE to just get the composite frames 
# to take into your own program for animation
#

pos1 <- interpolate_path(detections_filtered)
frameset <- make_frames(pos1, out_dir=paste0(getwd(),'/anim_out'), overwrite=TRUE)

