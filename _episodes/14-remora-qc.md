---
title: Quality Control Checks with Remora
teaching: 15
exercises: 0
questions:
- "How do I use Remora to quality check my data?"
---

`remora` [(Rapid Extraction of Marine Observations for Roving Animals)](https://github.com/IMOS-AnimalTracking/remora) is a program developed by researchers with IMOS to perform two critical functions. The first is to provide quality control checks for acoustic telemetry detection data. The second is to match detections with environmental
conditions at the time of detection. This lesson will cover the former functionality. 

`remora`'s original design only allowed for quality control on data collected by [IMOS](https://imos.org.au/facilities/animaltracking), in the area surrounding Australia. OTN has taken it on to globalize the code, allowing for detections from any location or institution to be processed. As such, some functions are not available in base remora, and must be taken from the OTN fork and the appropriate branch. 

To install the appropriate branch, run the following code:

~~~
install.packages('devtools')
library(devtools)

devtools::install_github('ocean-tracking-network/remora@nicerHulls', force=TRUE)
library(remora)
~~~
{: .language-r}


There are other packages that need to be installed and activated but these will have been covered in
the workshop setup file. 

We also need to download some test data. The data files are too big to store in the repo, so we've placed them on the OTN website. Run the following code to download and unzip the file to your working directory.

~~~
download.file("https://members.oceantrack.org/data/share/testdataotn.zip/@@download/file/testDataOTN.zip", "./testDataOTN.zip")
unzip("testDataOTN.zip")
~~~
{: .language-r}

The test data folder contains test data from UGACCI and FSUGG that we can test against, and a tif map of the world. We need the latter for certain QC tests. You can replace it with a file of your own if you so desire after this workshop. 

Now that we have some test data, we can start to run `remora`. 

Through this lesson we may refer to "IMOS-format" or "OTN-format" data. This may be confusing, since all the files have a '.csv' extension. What we're referring to are the names and presence of certain columns. Remora, having originally been written to handle IMOS' data, expects to receive a file with certain column names. OTN does not use the same column names, even though the data is often analogous. For example, in IMOS detection data, the column containing the species' common name is called `species_common_name`. In OTN detection data, the column is called `commonname`. The data in the two columns is analogous, but `remora` expects to see the former and will not accept the latter. 

To get around this limitation, we're in the process of writing a second package, `surimi`, that will allow users to translate data between institutional formats. At present, Surimi can only translate data from the OTN format to the IMOS format and from the IMOS format to the OTN format. However, we aim to expand this across more institutions to allow better transit of data products between analysis packages.

For the purposes of this code, you do not need to do any additional manipulation of the test data- Remora invokes the appropriate `surimi` functions to make the data ingestible.

Let's begin by making sure we have our raster of world landmasses. We can load this with the `raster` library as such:

~~~
world_raster <- raster::raster("./testDataOTN/NE2_50M_SR.tif")
~~~
{:.language-r}

We can now pass `world_raster` through to the QC process. Some of the tests to do with measuring distances require this raster. 

We'll also set up what we call our 'test vector'. This is a vector containing the names of all the tests you want to run. For the purposes of this workshop, we're going to run all of our tests, but you can comment out tests that you don't want to run. 

~~~
tests_vector <-  c("FDA_QC",
                   "Velocity_QC",
                   "Distance_QC",
                   "DetectionDistribution_QC",
                   "DistanceRelease_QC",
                   "ReleaseDate_QC",
                   "ReleaseLocation_QC",
                   "Detection_QC")
~~~
{:.language-r}

The tests are as follows: 
1. False Detection Algorithm: Is the detection likely to be false? Remora has an algorithm for determining whether or not a detection is false, but for OTN data, we invoke the Pincock filter as implemented in the `glatos` library. 
2. Velocity Check: Would the fish have had to travel at an unreasonable speed to get from its last detection to this one?
3. Distance Check: Was the fish detected an unreasonable distance from the last detection?
4. Detection Distribution: Was the fish detected within its species home range? 
5. Distance from Release: Was the fish detected a reasonable distance from the tag release? 
6. Release Date: Was the detection from before the release date? 
7. Release Location: Was the release within the species home range or 500km of the detection?
8. Detection Quality Control: An aggregation of the 7 previous tests to provide a final score as to the detection's likely legitimacy. Scores range from 1 (Valid) to 4 (Invalid).

An important note: if you're taking your data from an OTN node, the Release Date and Release Location QC will have already been done on the data during ingestion into OTN's database. You can still run them, and some other Remora functionality still depends on them, but they will not be counted towards the aggregation step, so as not to bias the results. 

Now, we can begin to operate on our files. First, create a vector containing the name of the detection file. 

~~~
otn_files_ugacci <- list(det = "./testDataOTN/ugaaci_matched_detections_2017.csv")
~~~
{: .language-r}

This format is necessary because if you have receiver and tag metadata, you can pass those in as well by supplying 'rec' and 'tag' entries in the vector. However, if all you have is a detection extract, Remora will use that to infer Receiver and Tag metadata. This is not a perfect system, but for most analyses you can do with Remora, it is good enough. 

You will note that some of the tests above reference a species home range. To determine that, we are going to use occurrence data from OBIS and GBIF to create a polygon that we can pass through to the QC functions. The code is contained within a function called getOccurrence, which invokes code written by [Steve Formel](https://www.gbif.us/post/2024/searching-with-aphiaids/) to get occurrence data from both OBIS and GBIF and combine it into a single dataframe.

~~~
#Add the scientific name of the species in question...
scientific_name <- "Acipenser oxyrinchus"

#And pass it through to getOccurrence.
sturgeonOccurrence <- getOccurrence(scientific_name)
~~~
{:.language-r}

The next step is to take the occurrence data and pass that to createPolygon, which will return a spatial object representing the species' home range. This function invokes code written by Jessica Castellanos, as well as the voluModel library, to create an alpha hull out of the occurrence data points. Most of the parameters we can pass to createPolygon are passed directly through to voluModel's `marineBackground` function. 

~~~
sturgeonPolygon <- createPolygon(sturgeonOccurrence, fraction=1, partsCount=1, buff=100000, clipToCoast = "aquatic")
~~~
{:.language-r}

Note that while here we are passing it the dataframe variable, if you have your own occurrence file you can pass the filename and createPolygon will read that in. 

With all of that in hand, we can run the QC function, like so: 

~~~
otn_test_tag_qc <- runQC(otn_files_ugacci, 
                         data_format = "otn", 
                         tests_vector = tests_vector, 
                         shapefile = sturgeonPolygon, 
                         col_spec = NULL, 
                         fda_type = "pincock", 
                         rollup = TRUE,
                         world_raster = world_raster,
                         .parallel = FALSE, .progress = TRUE)
~~~
{:.language-r}


Most of these parameters are self explanatory. Of note, though, is 'rollup', which- when set to TRUE, will return not only the normal Remora output (a nested tibble containing per-animal QC information), but a CSV file containing your original detection extract with the appropriate QC information attached. 

To get a quick visualization of our data, we can pass it to plotQC, a Remora function with some alterations for OTN data, and see an interactive Leaflet map of our data. 

~~~
plotQC(otn_test_tag_qc, distribution_shp = sturgeonPolygon, data_format = "otn")
~~~
{:.language-r}


This concludes the workshop material for Remora. For additional information about the package's original intentions, details can be found in the original [Hoenner et al](https://www.nature.com/articles/sdata2017206) paper that describes Remora's QC process.

