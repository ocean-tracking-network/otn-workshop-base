# GLATOS Intro Workshop ----

make_transition_flipped <- function(in_file, output = "out.tif",
                            output_dir = NULL, res = c(0.1, 0.1), 
                            all_touched = TRUE){
  
  # check to see if gdal is installed on machine- stop if not.
  gdalUtils::gdal_setInstallation()
  valid_install <- !is.null(getOption("gdalUtils_gdalPath"))
  if(!valid_install){
    stop("No GDAL installation found. Please install 'gdal' before continuing:\n\t- see: www.gdal.org\n\t- https://trac.osgeo.org/osgeo4w/ (windows)\n")
  }
  
  #Check if in_file is file, directory, or SpatialPolygonsDataFrame
  if(inherits(in_file, "character")) { 
    
    #check if in_file exists
    if(!file.exists(in_file)) stop(paste0("Input file or folder '", in_file, "' not found."))
    
    #check if file or directory and set layer name accordingly
    if(grepl("\\.shp$", in_file)){
      
      in_dir <- dirname(in_file)
      
      if(!file.exists(in_dir)) stop(paste0("'in_file' directory '", in_dir, "' not found."))
      
      #get layer name from file name
      in_layer <- basename(tools::file_path_sans_ext(basename(in_file)))
      
    } else { 
      
      in_dir <- in_file
      
      #use layer name as file name
      in_layer <- rgdal::ogrListLayers(in_dir)[1]      
      
    }
    
    #read shape file
    in_shp <- rgdal::readOGR(in_dir, layer = in_layer, verbose = FALSE) 
    
    #check if SpatialPolygonsDataFrame
    if (!inherits(in_shp, "SpatialPolygonsDataFrame")) stop(paste0("Input can only contain ",
                                                                   "polygon data."))
    
  } else if (inherits(in_file, "SpatialPolygonsDataFrame")) {
    
    in_shp <- in_file 
    
    #use incoming object name as layer
    in_layer <- deparse(substitute(in_file))
    
  } else {
    
    stop(paste0("'in_file' must be either an object of class 'SpatialPolygonsDataFrame' or\n", 
                " path to an ESRI Shapefile."))
    
  }
  
  
  #check projection and change if needed
  default_proj <- "+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"
  if(sp::proj4string(in_shp) != default_proj) {
    warning(paste0("Projection of input was not longlat WGS84, so conversion was attempted."),
            call. = FALSE)
    in_shp <- sp::spTransform(in_shp, sp::CRS(default_proj))
  }
  
  #write to temp dir and call gdal_rasterize
  temp_dir <- path.expand(file.path(tempdir(), in_layer))
  rgdal::writeOGR(in_shp, dsn = temp_dir, 
                  layer = in_layer,
                  driver = "ESRI Shapefile", 
                  overwrite_layer = TRUE)
  
  if(is.null(output_dir)) output_dir <- temp_dir
  
  burned <- gdalUtils::gdal_rasterize(temp_dir,
                                      dst_filename = path.expand(file.path(output_dir, output)),
                                      burn = 1,
                                      i = TRUE,
                                      tr = res,
                                      output_Raster = TRUE,
                                      at = all_touched)
  
  burned <- raster::raster(burned, layer = 1)
  
  tran <- function(x){if(x[1] * x[2] == 0){return(0)} else {return(1)}}
  tr1 <- gdistance::transition(burned, transitionFunction = tran, directions = 16)
  tr1 <- gdistance::geoCorrection(tr1, type="c")
  out <- list(transition = tr1, rast = burned)
  return(out)
}


setwd("./code/glatos/")
library(glatos)
library(dplyr)

# Get file path to example walleye GLATOS exports
# Detection Data
#det_file <- system.file("extdata", "walleye_detections.csv", package = "glatos")

det_file_name <- system.file("extdata", "blue_shark_detections.csv",
                        package = "glatos")

# Receiver Location
#rec_file <- system.file("extdata", "sample_receivers.csv", package = "glatos")

rec_file_name <- system.file("extdata", "hfx_deployments.csv",
                               package = "glatos")

# Load Project Workbook
#wb_file <- system.file("extdata", "walleye_workbook.xlsm", package = "glatos")

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

#workbook <- read_glatos_workbook(wb_file)
#head(workbook)

# GLATOS data types ####
#class(workbook)  # Workbook is a workbook, and a list

#names(workbook)  # Contains metadata, animals, receivers

# access the internals
#class(workbook$metadata) # wait, still a list?
#class(workbook$animals) 
#class(workbook[['receivers']])
##########################

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

# Visualizing Data - Abacus Plots ####
# ?glatos::abacus_plot
# customizable version of the standard VUE-derived abacus plots

abacus_plot(detections_w_events, 
            location_col='station', 
            main='NSBS Detections By Station') # can use plot() variables here, they get passed thru to plot()

# pick a single fish to plot
abacus_plot(detections_filtered[detections_filtered$animal_id== "NSBS-Hooker",],
            location_col='station',
            main="NSBS-Alison Detections By Station")

# subset of receivers?

receivers

receivers_subset <- receivers[receivers$station %in% c('HFX005', 'HFX031', 'HFX040'),]
receivers_subset

det_first <- min(detections$detection_timestamp_utc)
det_last <- max(detections$detection_timestamp_utc)
receivers_subset <- receivers_subset[
  receivers_subset$deploy_date_time < det_last &
    receivers_subset$recover_date_time > det_first &
    !is.na(receivers_subset$recover_date_time),] #removes deployments without recoveries

receivers_subset

locs <- unique(receivers_subset$station)

locs

receivers_subset <- filter(receivers_subset, deploy_date_time < det_last &
                             recover_date_time > det_first & 
                             !is.na(receivers_subset$recover_date_time))

receivers_subset

# Abacus Plots w/ Receiver History ####
# Using the receiver data frame from the start:
# See the receiver history behind the detections to know what you could see.

#Mutate new glatos_array column into the receivers.
receivers$glatos_array = receivers$station

abacus_plot(detections_filtered[detections_filtered$animal_id == 'NSBS-Hooker',],
            pch = 16,
            type='b',
            receiver_history=receivers,
            location_col = 'station')

names(receivers)


Canada <- getData('GADM', country="CAN", level=1)
NS <- Canada[Canada$NAME_1=="Nova Scotia",]

# Bubble Plots for Spatial Distribution of Fish ####
# bubble variable gets the summary data that was created to make the plot
detections_filtered
bubble <- detection_bubble_plot(detections_filtered, 
                                location_col = 'station',
                                map = NS,
                                col_grad=c('white', 'green'),
                                background_xlim = c(-66, -62),
                                background_ylim = c(42, 46))

# more complex example including zeroes by adding a specific
# receiver locations dataset, in this case the receivers dataset above.

bubble_custom <- detection_bubble_plot(detections_filtered,
                                       location_col='station',
                                       map = NS,
                                       background_xlim = c(-63.75, -63.25),
                                       background_ylim = c(44.25, 44.5),
                                       symbol_radius = 0.7,
                                       receiver_locs = receivers,
                                       col_grad=c('white', 'green'))

# Animations ####

# ?interpolate_path

# Supply an optional transition layer, built in make_transition.

library(sp) #for loading greatLakesPoly
library(raster) #for raster manipulation (e.g., crop)

# get example walleye detection data ####
#det_file <- system.file("extdata", "walleye_detections.csv",
#                        package = "glatos")
#det <- read_glatos_detections(det_file)

# take a look
head(detections)

# extract one fish and subset date ####
det <- detections[detections$animal_id == 'NSBS-Hooker' &
             detections$detection_timestamp_utc > as.POSIXct("2014-01-01") &
             detections$detection_timestamp_utc < as.POSIXct("2014-12-31"),]

# crop polygon to just outside Halifax Harbour ####
halifax <-  crop(NS, extent(-66, -62, 42, 45))

plot(halifax, col = "grey")
points(deploy_lat ~ deploy_long, data = det, pch = 20, col = "red", 
       xlim = c(-66, -62))

#make transition layer object ####
# Note: using make_transition2 here for simplicity, but 
#       make_transition is generally preferred for real application  
#       if your system can run it see ?make_transition
tran <- make_transition_flipped(halifax, res = c(0.1, 0.1))

plot(tran$rast, xlim = c(-66, -62), ylim = c(42, 45))
plot(halifax, add = TRUE)

# not high enough resolution- bump up resolution
tran1 <- make_transition_flipped(halifax, res = c(0.001, 0.001))


# plot to check resolution- much better
plot(tran1$rast, xlim = c(-66, -62), ylim = c(42, 45))
plot(halifax, add = TRUE)


# add fish detections to make sure they are "on the map"
# plot unique values only for simplicity
foo <- unique(det[, c("deploy_lat", "deploy_long")]) 
points(foo$deploy_long, foo$deploy_lat, pch = 20, col = "red")

# call with "transition matrix" (non-linear interpolation), other options ####
# note that it is quite a bit slower due than linear interpolation
pos2 <- interpolate_path(det, trans = tran1$transition, out_class = "data.table")

plot(halifax, col = "grey")
points(latitude ~ longitude, data = pos2, pch=20, col='red', cex=0.5)

# Make frames out of the data points ####
# ?make_frames

# just gimme the animation!
#setwd('~/code/glatos')
frameset <- make_frames(pos2, bg_map=halifax, background_ylim = c(42, 45), background_xlim = c(-66, -62), overwrite=TRUE)

?make_frames

# can set animate = FALSE to just get the composite frames 
# to take into your own program for animation
#

pos1 <- interpolate_path(det)
frameset <- make_frames(pos1, bg_map=halifax, background_ylim = c(42, 45), background_xlim = c(-66, -62), out_dir=paste0(getwd(),'/anim_out'), overwrite=TRUE)

