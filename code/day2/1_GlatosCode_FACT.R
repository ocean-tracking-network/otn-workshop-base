# 07 - Introduction to glatos ####

## Set your working directory

setwd("./Work/otn-workshop-base/data/fact/")
library(glatos)
library(tidyverse)
library(VTrack)
library(lubridate)

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
for (detfile in list.files('.', full.names = TRUE, pattern = "tqcs.*\\.zip")) {
  print(detfile)
  tmp_dets <- read_csv(detfile, col_types = format)
  detections <- bind_rows(detections, tmp_dets)
}
write_csv(detections, 'all_dets.csv', append = FALSE)


## glatos help files are helpful!!
?read_otn_deployments

# Save our detections file data into a dataframe called detections
detections <- read_otn_detections('all_dets.csv')

detections <- detections %>% slice(1:100000) # subset our example data to help this workshop run

# View first 2 rows of output
head(detections, 2)

## Filtering False Detections ####
## ?glatos::false_detections

# write the filtered data (no rows deleted, just a filter column added)
# to a new det_filtered object
#detections$transmitter_codespace = unlist(detections$transmitter_codespace)
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
tagged_fish <- c('TQCS-1049258-2008-02-14', '	TQCS-1049269-2008-02-28')

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

subset_animals <- c('TQCS-1049274-2008-02-28', 'TQCS-1049271-2008-02-28', 'TQCS-1049258-2008-02-14')
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

?prepare_deploy_sheet

tags <- prepare_tag_sheet('TQCS_metadata_tagging.xlsx',sheet_name=1, header_line = 1)
receivers <- prepare_deploy_sheet('TEQ_Deployments_201001_201201.xlsx', sheet_name = 1, header_line = 0)

#tags <- tags %>%
#  mutate(time = full_dates)

#Add columns missing from FACT extracts.
detections_filtered['sensorvalue'] = NA
detections_filtered['sensorunit'] = NA

# Rename the station names in receivers to match station names in detections
receivers <- receivers %>% mutate(station=substring(station, 4))

ATTdata <- convert_otn_to_att(detections_filtered, tags, deploymentSheet = receivers)

?glatos::convert_otn_to_att

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
# Get the data for only 'TQCS-1049273-2008-02-28'
coa_single <- coa %>% filter(Tag.ID == 'TQCS-1049273-2008-02-28')
view(coa_single)

# We'll use raster to get the polygon
library(raster)
USA <- getData('GADM', country="USA", level=1)
MD <- USA[USA$NAME_1=="Maryland",]

#Alternative method of getting the polygon. 
library(raster)
f <-  'http://biogeo.ucdavis.edu/data/gadm3.6/Rsp/gadm36_USA_1_sp.rds'
b <- basename(f)
download.file(f, b, mode="wb", method="curl")
USA <- readRDS('gadm36_USA_1_sp.rds')
FL <- USA[USA$NAME_1=="Florida",]

# plot the object and zoom in to St. Lucie River and Jupiter Inlet. Set colour of ground to green Add labels to the axises
plot(FL, xlim=c(-80.75, -80), ylim=c(27, 27.5), col='green', xlab="Longitude", ylab="Latitude")

# For much more zoomed in plot
# plot(FL, xlim=c(-80.4, -80.0), ylim=c(27, 27.3), col='green', xlab="Longitude", ylab="Latitude")

# Create a palette
color <- c(colorRampPalette(c('pink', 'red'))(max(coa_single$Number.of.Detections)))

#add the points
plot.new()
points(coa_single$Longitude.coa, coa_single$Latitude.coa, pch=19, col=color[coa_single$Number.of.Detections],
    cex=log(coa_single$Number.of.Stations) + 0.5) # cex is for point size. natural log is for scaling purposes

# add axes and title
axis(1)
axis(2)
title("Centers of Activities for TQCS-1049273-2008-02-28")

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
            main='TQCS Detections by Station') # can use plot() variables here, they get passed thru to plot()

# pick a single fish to plot
abacus_plot(detections_filtered[detections_filtered$animal_id== "TQCS-1049273-2008-02-28",],
            location_col='station',
            main="TQCS-1049273-2008-02-28 Detections By Station")

# Bubble Plots for Spatial Distribution of Fish ####
# bubble variable gets the summary data that was created to make the plot
detections_filtered

?detection_bubble_plot

bubble_station <- detection_bubble_plot(detections_filtered, 
                                out_file = '../tqcs_bubble.png',
                                location_col = 'station',
                                map = FL,
                                col_grad=c('white', 'green'),
                                background_xlim = c(-81, -80),
                                background_ylim = c(26, 28))
bubble_station


# Challenge 1 ----
# Create a bubble plot of that bay we zoomed in earlier. Set the bounding box using the provided nw + se cordinates, change the colour scale and
# resize the points to be smaller. As a bonus, add points for the other receivers that don't have any detections.
# Hint: ?detection_bubble_plot will help a lot
# Here's some code to get you started

nw <- c(38.75, -76.75)
se <- c(39, -76.25)
