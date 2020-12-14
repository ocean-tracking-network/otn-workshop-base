---
title: Introduction to `actel`
teaching: 45
exercises: 0
questions:

objectives:

keypoints:


---

`actel` is designed for studies where animals tagged with acoustic tags are expected to move through receiver arrays. `actel` combines the advantages of automatic sorting and checking of animal movements with the possibility for user intervention on tags that deviate from expected behaviour. The three analysis functions: explore, migration and residency, allow the users to analyse their data in a systematic way, making it easy to compare results from different studies.


(Speaker: Dr. Hugo Flavio, hflavio@wlu.ca)

- [actel: Standardised analysis of acoustic telemetry data from animals moving through receiver arrays](../Resources/actel_paper_published_version.pdf)

- [Powerpoint](../Resources/actel_introduction.ppsx)

### Exploring
~~~
library(actel)

# The first thing you want to do when you try out a package is...
# explore the documentation!

# See the package level documentation:
?actel

# See the manual:
browseVignettes("actel")

# access the paper:
citation("actel")

# Finally, every function in actel contains detailed documentation
# of the function's purpose and parameters. You can access this
# documentation by typing a question mark before the function name.
# e.g.: ?explore
~~~
{: .language-r}

## Example data exercise

~~~
# Start by checking where you are working with (it is always good to known this)
getwd()

# We will deploy actel's example files into a new folder, called "actel_example".
# exampleWorkspace() will provide you with some information about how to run the example analysis.
exampleWorkspace("actel_example")

# Side note: When preparing your own data, you can crate template files
# with the function createWorkspace("directory_name")

# Take a minute to explore the folder contents. You will find the files that were presented earlier.

# -----------------------

# If you read the information provided by exampleWorkspace, you will find these two commands:

# move into the newly created folder
setwd('actel_example')

# Run analysis. Note: This will open an analysis report on your web browser.
exp.results <- explore(tz = 'Europe/Copenhagen', report = TRUE)

# If the explore analysis failed while producing the report,
# run the line below to load the results directly from the results file.
exp.results <- dataToList("actel_example_results.RData")

# Because this is an example dataset, this analysis will run very smoothly. 
# Real data is not always this nice to us!

# ----------
# IF your analysis failed while compiling the report, you can load 
# the saved results back in using the dataToList() function:
exp.results <- dataToList("actel_example_results.RData")

# IF your analysis failed before you had a chance to save the results,
# load the pre-compiled results, so you can keep up with the workshop.
# Remember to change the path so R can find the RData file.
exp.results <- dataToList("path/to/pre-compiled_results.RData")
# ----------

# -----------------------

# What is inside the output?
names(exp.results)

# What is inside the valid movements?
names(exp.results$valid.movements)

# let's have a look at the first one:
exp.results$valid.movements[["R64K-4451"]]

# and here are the respective valid detections:
exp.results$valid.detections[["R64K-4451"]]

# We can use these results to obtain our own plots (We will go into that later)
~~~
{: .language-r}


## Distances matrix exercise

~~~
# Let's load the spatial file individually, so we can have a look at it.
spatial <- loadSpatial()
head(spatial)

# When doing the following steps, it is imperative that the coordinate reference 
# system (CRS) of the shapefile and of the points in the spatial file are the same.
# In this case, the values in columns "x" and "y" are already in the right CRS.

# loadShape will rasterize the input shape, using the "size" argument as a reference
# for the pixel size. Note: The units of the "size" will be the same as the units
# of the shapefile projection (i.e. metres for metric projections, and degrees for latlong systems)
#
# In this case, we are using a metric system, so we are saying that we want the pixel
# size to be 10 metres.
#
# NOTE: Change the 'path' to the folder where you have the shape file.
# Â¨Â¨Â¨Â¨Â¨Â¨Â¨Â¨Â¨Â¨Â¨Â¨Â¨Â¨Â¨Â¨Â¨Â¨Â¨Â¨Â¨Â¨Â¨Â¨Â¨Â¨Â¨Â¨Â¨Â¨Â¨Â¨Â¨Â¨Â¨Â¨Â¨Â¨Â¨Â¨Â¨Â¨Â¨Â¨Â¨Â¨Â¨Â¨Â¨Â¨Â¨Â¨Â¨Â¨Â¨Â¨Â¨Â¨Â¨Â¨Â¨Â¨Â¨Â¨Â¨Â¨Â¨Â¨
water <- loadShape(path = "C:/Users/hdmfla/Google Drive/workshops/2020-12-17_FACT/actel_intro",
									 shape = "stora_shape_epsg32632.shp", size = 10,
									 coord.x = "x", coord.y = "y")

# The function above can run without the coord.x and coord.y arguments. However, by including them,
# you are allowing actel to load the spatial.csv file on the fly and check if the spatial points
# (i.e. hydrophone stations and release sites) are positioned in water. This is very important,
# as any point position on land will be cut-off during distance calculations.

# Now we need to create a transition layer, which R will use to estimate the distances
tl <- transitionLayer(water)

# We are ready to try it out! distancesMatrix will automatically search for a "spatial.csv"
# file in the current directory, so remember to keep that file up to date!
dist.mat <- distancesMatrix(tl, coord.x = "x", coord.y = "y")

# have a look at it:
dist.mat
~~~
{: .language-r}

## migration and residency

~~~
# Let's go ahead and try running migration() and residency() on this dataset.
mig.results <- migration(tz = 'Europe/Copenhagen', report = TRUE)

# now try copying the whole block (user decisions included) and running it at once.
res.results <- residency(tz = 'Europe/Copenhagen', report = TRUE)
comment
This is a lovely fish
n
y
# explore the reports to see what's new!

# Note: There is a known bug in residency() as of actel 1.2.0, which for some datasets
# will cause a crash with the following error message:
#
# Error in tableInteraction(moves = secmoves, tag = tag, trigger = the.warning,  : 
#  argument "save.tables.locally" is missing, with no default
#
# This has already been corrected in development and a fix will be released in actel 1.2.1.
# In the meantime, if you come across this error, get in contact with me and I will guide
# you through how to install the development version.
~~~
{: .language-r}

## For home: Transforming the results
```
# Try some of the stuff in this manual page!
vignette("f-0_post_functions", "actel")
~~~
{: .language-r}
