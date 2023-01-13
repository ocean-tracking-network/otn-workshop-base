---
title: Quality Control Checks with Remora
teaching: 0
exercises: 0
questions:
- "How do I use Remora to quality check my data?"
---

`remora` (Rapid Extraction of Marine Observations for Roving Animals) is a program developed by researchers with IMOS to perform two critical functions. The first is to provide quality control
checks for acoustic telemetry detection data. The second is to match detections with environmental
conditions at the time of detection. This lesson will cover the former functionality. 

`remora`'s original design only allowed for data collected by IMOS, in the area surrounding Australia.
OTN has taken it on to globalize the code, allowing for detections from any location or institution
to be processed. As such, some functions are not available in base remora, and must be taken from
the OTN fork and the appropriate branch. 

To install the appropriate branch, run the following code:

~~~
install.packages('devtools')
library(devtools)

devtools::install_github('ocean-tracking-network/remora@get_data_qc', force=TRUE)
library(remora)
~~~
{: .langauge-r}

There are other packages that need to be installed and activated but these will have been covered in
the workshop setup file. 

We also need to download some test data. The data files are too big to store in the repo, so we've placed them on the OTN website. Run the following code to download and unzip the file to your working directory.

~~~
download.file("https://members.oceantrack.org/data/share/testdataotn.zip/@@download/file/testDataOTN.zip", "./testDataOTN.zip")
unzip("testDataOTN.zip")
~~~
{: .language-r}

The test data folder contains a simplified OTN-format detection file (qc_princess.csv), a tif map of the world, and a selection of shapefiles representing the home ranges of different species of sharks, rays, and chimeras. We will use these latter two files for certain QC tests. In the future, you'll be able to replace this test data with world maps and animal range shapefiles that better align with your data. 

Now that we have some test data, we can start to run `remora`. First, we'll do a few things just to show how the code works. The QC functions take as input a list of filepaths. There are four files that must be supplied for the QC code to run properly, in base Remora (we'll get into some of the newer functionality). These are as follows: 

* A file containing detection information. 
* A file containing receiver deployment metadata.
* A file containing tag metadata.
* A file containing animal measurement information.

The code below shows what a complete list might look like. We won't use `imos_files` for this lesson, but it is illustrative.

~~~
imos_files <- list(det = system.file(file.path("test_data","IMOS_detections.csv"), package = "remora"),
                   rmeta = system.file(file.path("test_data","IMOS_receiver_deployment_metadata.csv"),
                                       package = "remora"),
                   tmeta = system.file(file.path("test_data","IMOS_transmitter_deployment_metadata.csv"),
                                       package = "remora"),
                   meas = system.file(file.path("test_data","IMOS_animal_measurements.csv"),
                                      package = "remora"))
~~~
{: .language-r}

Through this lesson we may refer to "IMOS-format" or "OTN-format" data. This may be confusing, since all the files are CSV format. What we're referring to are the names and presence of certain columns. Remora, having originally been written to handle IMOS' data, expects to receive a file with certain column names. OTN does not use the same column names, even though the data is often analogous. For example, in IMOS detection data, the column containing the species' common name is called `species_common_name`. In OTN detection data, the column is called `commonname`. The data in the two columns is analogous, but `remora` expects to see the former and will not accept the latter. 

To get around this limitation, we've written additional functions that will take OTN-format data and convert it to IMOS-format data so as to make it ingestible by `remora`. We'll demonstrate what these functions look like and how to run them, although do note that if you pass OTN-format data to the QC functions directly (as we will later), you do not need to run this function- it will happen as part of the QC process. 

To map your data from OTN to IMOS format, we can use the following code. Note that we are only passing in a detection extract dataframe- keep that in mind when we inspect the results of the mapping function.

~~~
#Read in the test data as a CSV. 
otn_test_data <- read_csv("./testDataOTN/qc_princess.csv") #Put your path to your test file here. 
#Return the mapped data
otn_mapped_test <- remora::otn_imos_column_map(otn_test_data)
#If you want to check your work. otn_mapped_test is a list of dataframes, so keep that in mind. 
View(otn_mapped_test)
~~~
{: .language-r}

Note that although we only supplied a detection extract to `otn_imos_column_map`, the returned dataframe contains multiple formatted dataframes. This is because we have built the code to allow for a researcher to supply only their detection extracts. In this event, receiver and tag metadata are derived from information in the detection extract. These are incomplete, but they are enough to run some QC tests on. 

This is just illustrative, for now. As stated, this functionality will be run if you pass OTN data directly to the QC functions. Let's do that now. 

First, set up a list of file paths, as we did initially with the IMOS data above. 

~~~
otn_files <- list(det = "./testDataOTN/qc_princess.csv")
~~~
{: .language-r}

In keeping with the above, we're just going to supply a detection extract rather than all of the relevant metadata. This will illustrate the functionality we have designed. You are able to supply receiver and tag metadata if you have it, however. 

Before we can run the QC checks, we need to set up those shapefiles we downloaded so that `remora` can use them. First, we'll set up the shape representing blue shark distribution range. 

~~~
#Load the shapefile with st_read. 
shark_shp <- sf::st_read("./testDataOTN/SHARKS_RAYS_CHIMAERAS/SHARKS_RAYS_CHIMAERAS.shp")
#We're using the binomial name and bounding box that befits our species and area but feel free to sub in your own when you work with other datasets.
blue_shark_shp <- shark_shp[shark_shp$binomial == 'Prionace glauca',]
blue_shark_crop <- st_crop(blue_shark_shp,  xmin=-68.4, ymin=42.82, xmax=-60.53, ymax=45.0)
~~~
{: .language-r}

Now we need to create a transition layer, which is a simple raster that will help QC tests determine which areas represent water and which ones represent land. We can use the `glatos` library that we've already covered to do this. 

~~~
#Make a transition layer for later...
shark_transition <- glatos::make_transition2(blue_shark_crop)
shark_tr <- shark_transition$transition
~~~
{: .language-r}

We will also need to cast our cropped shapefile to a Spatial polygon so that `remora` can use it with an awareness of latitude and longitude. 

~~~
#And also a spatial polygon that we can use later. 
blue_shark_spatial <- as_Spatial(blue_shark_crop)
~~~
{: .language-r}

The last element we need to set up is a map of coastlines, which `remora` will use to tie together the above elements to perform QC tests that involve, for example, calculating shortest distance, or whether or not the fish was detected in its home range (we will outline the available tests below). For this, we will use a mid-resolution .tif file from Natural Earth, which we will then crop using our cropped shapefile, giving us an appropriately sized chunk of coastline data. 

~~~
#We also need a raster for the ocean. We'll load this from a mid-resolution tif file, for testing purposes. 
world_raster <- raster("./testDataOTN/NE2_50M_SR.tif")
#And crop it based on our cropped blue shark extent. 
world_raster_sub <- crop(world_raster, blue_shark_crop)
~~~
{: .language-r}

Note that although we have supplied these files as test data, these specific files aren't the only ones that can be used. If you have data sources that better suit your own data, then when you QC it you should use them. So far this is all about giving you an awareness of what Remora needs to get set up. 

Now that we have all of that set up, we can finally run our data through the quality control tests. That looks like this: 

~~~
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
otn_test_tag_qc <- remora::runQC(otn_files, data_format = "otn", tests_vector = tests_vector, .parallel = FALSE, .progress = TRUE)
~~~
{: .language-r}