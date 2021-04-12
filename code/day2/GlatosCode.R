# 07 - Introduction to GLATOS ####

## Set your working directory

setwd("./data/")  
library(glatos)
library(tidyverse)
library(VTrack)

# First we need to create one detections file from all our detection extracts.
library(utils)

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
detections <- tibble()
for (detfile in list.files('.', full.names = TRUE, pattern = "proj.*\\.zip")) {
  print(detfile)
  tmp_dets <- read_csv(detfile, col_types = format)
  detections <- bind_rows(detections, tmp_dets)
}
write_csv(detections, 'all_dets.csv', append = FALSE)


## GLATOS help files are helpful!!
?read_otn_deployments

# Save our detections file data into a dataframe called detections
detections <- read_otn_detections('all_dets.csv')


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


# You can make your own column and use that as the location_col
# For example we will create a uniq_station column for if you have duplicate station names across projects
detections_filtered_special <- detections_filtered %>% 
  mutate(station_uniq = paste(glatos_array, station, sep=':'))

sum_location_special <- summarize_detections(detections_filtered_special, location_col = 'station_uniq', summ_type='location')

head(sum_location_special)

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
                           location_col = 'station', 
                           time_sep=3600)

head(events)


# keep detections, but add a 'group' column for each event group
detections_w_events <- detection_events(detections_filtered,
                                        location_col = 'station', 
                                        time_sep=3600, condense=FALSE)

# 08 - More Features of glatos ####


?residence_index

#Using all the events data will take too long, we will subset to just use a couple animals
events %>% group_by(animal_id) %>% summarise(count=n()) %>% arrange(desc(count))

subset_animals <- c('PROJ59-1191631-2014-07-09', 'PROJ59-1191628-2014-07-07', 'PROJ64-1218527-2016-06-07')
events_subset <- events %>% filter(animal_id %in% subset_animals)

events_subset
# Calc residence index using the Kessel method
rik_data <- residence_index(events_subset, 
                            calculation_method = 'kessel')
rik_data

# Calc residence index using the time interval method, interval set to 6 hours
# "Kessel" method is a special case of "time_interval" where time_interval_size = "1 day"
rit_data <- residence_index(events_subset, 
                            calculation_method = 'time_interval', 
                            time_interval_size = "6 hours")
rit_data
 
# Converting GLATOS/FACT/OTN-style dataframes to ATT format for use with VTrack ####

?convert_otn_to_att

tags <- prepare_tag_sheet('Tag_Metadata/Proj58_Metadata_cownoseray.xls',sheet = 2, start = 5)

#To fix the datetimes, we will use the code Bruce showed yesterday
normDate <- Vectorize(function(x) {
  if (!is.na(suppressWarnings(as.numeric(x))))  # Win excel
    as.Date(as.numeric(x), origin="1899-12-30")
  else
    as.Date(x, format="%y/%m/%d")
})

res <- as.Date(normDate(tags$time[0:52]), origin="1970-01-01")

full_dates = c(ymd_hms(res, truncated = 3), ymd_hms(tags$time[53:89]))
View(full_dates)

tags <- tags %>%
  mutate(time = full_dates)

# Filter our dets so we only have proj58 ones
proj58_detections <- detections_filtered %>%  filter(collectioncode == 'PROJ58')

?read_otn_deployments
deploys <- read_otn_deployments('matos_FineToShare_stations_receivers_202104091205.csv')
ATTdata <- convert_otn_to_att(proj58_detections, tags, deploymentObj = deploys)

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

coa %>% group_by(Tag.ID) %>% summarize(n())
# Plot a COA
# Get the data for only 'PROJ58-1218518-2015-09-16'
coa_single <- coa %>% filter(Tag.ID == 'PROJ58-1218518-2015-09-16')

# We'll use raster to get the polygon
library(raster)
USA <- getData('GADM', country="USA", level=1)
MD <- USA[USA$NAME_1=="Maryland",]

# plot the object and zoom in to lake Huron. Set colour of ground to green Add labels to the axises
plot(MD, xlim=c(-76, -77), ylim=c(38, 40), col='green', xlab="Longitude", ylab="Latitude")

# For much more zoomed in plot
# plot(MD, xlim=c(-76.25, -76.75), ylim=c(38.75, 39), col='green', xlab="Longitude", ylab="Latitude")

# Create a palette
color <- c(colorRampPalette(c('pink', 'red'))(max(coa_single$Number.of.Detections)))

#add the points
points(coa_single$Longitude.coa, coa_single$Latitude.coa, pch=19, col=color[coa_single$Number.of.Detections], 
    cex=log(coa_single$Number.of.Stations) + 0.5) # cex is for point size. natural log is for scaling purposes

# add axises and title
axis(1)
axis(2)
title("Centers of Activities for PROJ58-1218518-2015-09-16")

# Dispersal information
# ?dispersalSummary
# Units are in Euclidean distance
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
            main='ACT Detections by Station') # can use plot() variables here, they get passed thru to plot()

# pick a single fish to plot
abacus_plot(detections_filtered[detections_filtered$animal_id== "PROJ58-1218508-2015-10-13",],
            location_col='station',
            main="PROJ58-1218508-2015-10-13 Detections By Station")

# Bubble Plots for Spatial Distribution of Fish ####
# bubble variable gets the summary data that was created to make the plot
detections_filtered

?detection_bubble_plot

bubble_station <- detection_bubble_plot(detections_filtered,
                                        background_ylim = c(38, 40),
                                        background_xlim = c(-77, -76),
                                        map = MD,
                                        location_col = 'station',
                                        out_file = 'act_bubbles_by_stations.png')
bubble_station

bubble_array <- detection_bubble_plot(detections_filtered,
                                      background_ylim = c(38, 40),
                                      background_xlim = c(-77, -76),
                                      map = MD,
                                      out_file = 'act_bubbles_by_array.png')
bubble_array


# Challenge 1 ----
# Create a bubble plot of the station in Lake Erie only. Set the bounding box using the provided nw + se cordinates and 
# resize the points. As a bonus, add points for the other receivers in Lake Erie.
# Hint: ?detection_bubble_plot will help a lot
# Here's some code to get you started
erie_arrays <-c("DRF", "DRL", "DRU", "MAU", "RAR", "SCL", "SCM", "TSR") 
nw <- c(43, -83.75) 
se <- c(41.25, -82) 