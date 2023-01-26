#To install the appropriate branch, run the following code:

install.packages('devtools')
library(devtools)

devtools::install_github('ocean-tracking-network/remora@get_data_qc', force=TRUE)
library(remora)

# Run the following code to download and unzip the file to your working directory.
download.file("https://members.oceantrack.org/data/share/testdataotn.zip/@@download/file/testDataOTN.zip", 
              "./testDataOTN.zip")

unzip("testDataOTN.zip")

#To map your data from OTN to IMOS format, we can use the following code. 
# Note that we are only passing in a detection extract dataframe- 
# keep that in mind when we inspect the results of the mapping function.

#Read in the test data as a CSV. 
otn_test_data <- read_csv("./testDataOTN/qc_princess.csv") #Put your path to your test file here. 

#Return the mapped data
otn_mapped_test <- remora::otn_imos_column_map(otn_test_data)

#If you want to check your work. otn_mapped_test is a list of dataframes, so keep that in mind. 
View(otn_mapped_test)

# set up a list of file paths

otn_files <- list(det = "./testDataOTN/qc_princess.csv")

#Load the shapefile with st_read. 
shark_shp <- sf::st_read("./testDataOTN/SHARKS_RAYS_CHIMAERAS/SHARKS_RAYS_CHIMAERAS.shp")

#We're using the binomial name and bounding box that befits our species and area but feel free to sub in your own when you work with other datasets.
blue_shark_shp <- shark_shp[shark_shp$binomial == 'Prionace glauca',]
blue_shark_crop <- st_crop(blue_shark_shp,  xmin=-68.4, ymin=42.82, xmax=-60.53, ymax=45.0)

#Make a transition layer for later...
shark_transition <- glatos::make_transition2(blue_shark_crop)
shark_tr <- shark_transition$transition

#And also a spatial polygon that we can use later. 
blue_shark_spatial <- as_Spatial(blue_shark_crop)

#We also need a raster for the ocean. We'll load this from a mid-resolution tif file, for testing purposes. 
world_raster <- raster("./testDataOTN/NE2_50M_SR.tif")

#And crop it based on our cropped blue shark extent. 
world_raster_sub <- crop(world_raster, blue_shark_crop)

#These are the available tests at time of writing. Detection Distribution isn't working yet and so we have commented it out. 
tests_vector <-  c("FDA_QC",
                   "Velocity_QC",
                   "Distance_QC",
                   #"DetectionDistribution_QC",
                   "DistanceRelease_QC",
                   "ReleaseDate_QC",
                   "ReleaseLocation_QC",
                   "Detection_QC")

#In a perfect world, when you run this code, you will get output with QC attached. 
otn_test_tag_qc <- remora::runQC(otn_files, data_format = "otn", 
                                 tests_vector = tests_vector, .parallel = FALSE, .progress = TRUE)

