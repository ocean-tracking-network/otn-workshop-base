---
title: Introduction to actel
teaching: 45
exercises: 0
questions:

objectives:

keypoints:
---

`actel` is designed for studies where animals tagged with acoustic tags are expected to move through receiver arrays. `actel` combines the advantages of automatic sorting and checking of animal movements with the possibility for user intervention on tags that deviate from expected behaviour. The three analysis functions: explore, migration and residency, allow the users to analyse their data in a systematic way, making it easy to compare results from different studies.

Author: Dr. Hugo Flavio, ( hflavio@wlu.ca )

Actel on GitHub: https://github.com/hugomflavio/actel/

- [PAPER - actel: Standardised analysis of acoustic telemetry data from animals moving through receiver arrays](../Resources/actel_paper_published_version.pdf)

- [POWERPOINT](../Resources/actel_introduction.ppsx)


### Actel - a package for the analysis of acoustic telemetry data

`actel` seeks to be a one-stop package that guides the user through the compilation and cleaning of their telemetry data, the description of their study system, and the production of many reports and analyses that are generally applicable to closed-system telemetry projects. `actel` tracks receiver deployments, tag releases, and detection data, as well as an additional concept of receiver groups and a network of the interconnectivity between them within our study area, and uses all of this information to raise warnings and potential oddities in the detection data to the user.

![Actel - a study's receivers and arrays split up into sections](../Resources/actel_study_sections.png)

![Actel graph of receiver group interactivity](../Resources/actel_mb_arrays.svg)

If you're working in river systems, you've probably got a sense of which receivers form arrays. There is a larger-order grouping you can make called 'sections', and this will be something we can inter-compare our results with.

### Preparing to use `actel`

With our receiver, tag, and detection data mapped to `actel`'s formats, and after creating our receiver groups and graphing out how detected animals may move between them, we can leverage `actel`'s analyses for our own datasets. Thanks to some efforts on the part of Hugo and of the `glatos` development team, we can move fairly easily with our `glatos` data into `actel`.

`actel`'s standard suite of analyses are grouped into three main functions - explore(), migration(), and residency(). As we will see in this and the next modules, these functions specialize in terms of their outputs but accept the same input data and arguments.

The first thing we will do is use `actel`'s built-in dataset to ensure we've got a working environment, and also to see what sorts of default analysis output Actel can give us.



### Exploring

~~~
library("actel")

# The first thing you want to do when you try out a package is...
# explore the documentation!

# See the package level documentation:
?actel

# See the manual:
browseVignettes("actel")

# Get the citation for actel, and access the paper:
citation("actel")

# Finally, every function in actel contains detailed documentation
# of the function's purpose and parameters. You can access this
# documentation by typing a question mark before the function name.
# e.g.: ?explore
~~~
{: .language-r}

## Example data exercise

~~~
# Start by checking where your working directory is (it is always good to know this)
getwd()

# We will then deploy actel's example files into a new folder, called "actel_example".
# exampleWorkspace() will provide you with some information about how to run the example analysis.
exampleWorkspace("actel_example")

# Side note: When preparing your own data, you can create the initial template files
# with the function createWorkspace("directory_name")

# Take a minute to explore this folder's contents.

# -----------------------
~~~
{: .language-r}

![Actel example data folder output](/Resources/actel_example_folder.PNG)

~~~
# move into the newly created folder
setwd('actel_example')

# Run analysis. Note: This will open an analysis report on your web browser.
exp.results <- explore(tz = 'Europe/Copenhagen', report = TRUE)

# Because this is an example dataset, this analysis will run very smoothly. 
# Real data is not always this nice to us!

# ----------
# If your analysis failed while compiling the report, you can load 
# the saved results back in using the dataToList() function:
exp.results <- dataToList("actel_explore_results.RData")

# If your analysis failed before you had a chance to save the results,
# load the pre-compiled results, so you can keep up with the workshop.
# Remember to change the path so R can find the RData file.
exp.results <- dataToList("pre-compiled_results.RData")
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
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
water <- loadShape(path = "replace/with/path/to/shapefile",
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

# Now try copy-pasting the next five lines as a block and run it all at once.
res.results <- residency(tz = 'Europe/Copenhagen', report = TRUE)
comment
This is a lovely fish
n
y
# R will know to answer each of the questions that pop up during the analysis
# with the lines you copy-pasted together with your code!

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
~~~
# Try some of the stuff in this manual page!
vignette("f-0_post_functions", "actel")
~~~
{: .language-r}
