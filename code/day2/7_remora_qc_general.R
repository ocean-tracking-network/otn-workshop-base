library(devtools)
library(httr2)
library(dplyr)
library(raster)
library(readr)
library(terra)
library(tidyverse)
library(sf)
library(sp)
library(raster)
library(stars)
library(glatos)
library(utils)
library(geosphere)
library(rangeBuilder)
library(surimi)

devtools::install_github("ocean-tracking-network/remora@nicerHulls", force=TRUE)
library(remora)

setwd('YOUR/PATH/TO/remora')

download.file("https://members.oceantrack.org/data/share/testdataotn.zip/@@download/file/testDataOTN.zip", "./testDataOTN.zip")
unzip("testDataOTN.zip")

world_raster <- raster::raster("./testDataOTN/NE2_50M_SR.tif")

tests_vector <-  c("FDA_QC",
                   "Velocity_QC",
                   "Distance_QC",
                   "DetectionDistribution_QC",
                   "DistanceRelease_QC",
                   "ReleaseDate_QC",
                   "ReleaseLocation_QC",
                   "Detection_QC")

otn_files_ugacci <- list(det = "./testDataOTN/ugaaci_matched_detections_2017.csv")

scientific_name <- "Acipenser oxyrinchus"

sturgeonOccurrence <- getOccurrence(scientific_name)

sturgeonPolygon <- createPolygon(sturgeonOccurrence, fraction=1, partsCount=1, buff=100000, clipToCoast = "aquatic")

otn_test_tag_qc <- runQC(otn_files_ugacci, 
                         data_format = "otn", 
                         tests_vector = tests_vector, 
                         shapefile = sturgeonPolygon, 
                         col_spec = NULL, 
                         fda_type = "pincock", 
                         rollup = TRUE,
                         world_raster = world_raster,
                         .parallel = FALSE, .progress = TRUE)

plotQC(otn_test_tag_qc, distribution_shp = sturgeonPolygon, data_format = "otn")


otn_files_fsugg <- list(det = "./testDataOTN/fsugg_matched_detections_2017.csv")

scientific_name <- "Epinephelus itajara"

grouperOccurrence <- getOccurrence(scientific_name)

#OBIS is a data system populated by people observing biodiversity. So, it's very good about having data where there are people. - Some paper Jon read.
#grouperPolygon <- createPolygon(grouperOccurrence, fraction=1, partsCount=1, buff=10000, clipToCoast = "aquatic")
grouperPolygon <- createPolygon(grouperOccurrence, buff=2000, clipToCoast = "aquatic")

otn_test_tag_qc <- runQC(otn_files_fsugg, 
                         data_format = "otn", 
                         tests_vector = tests_vector, 
                         shapefile = grouperPolygon, 
                         col_spec = NULL, 
                         fda_type = "pincock", 
                         rollup = TRUE,
                         world_raster = world_raster,
                         .parallel = FALSE, .progress = TRUE)

plotQC(otn_test_tag_qc, distribution_shp = grouperPolygon, data_format = "otn")
