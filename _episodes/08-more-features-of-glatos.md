---
title: More Features of glatos
teaching: 15
exercises: 0
questions:
    - "What other features does glatos offer?"
---
**Note to instructors: please choose the relevant Network below when teaching**

## ACT Node

`glatos` has more advanced analytic tools that let you manipulate your data further. We'll cover a few of these features now, to show you how to take your data beyond just filtering and event creation. We'll also show you how to move your data from `glatos` to VTrack, another powerful suite of data manipulation tools. By combining the `glatos` package's powerful built-in functions with its interoperability across scientific R packages, we'll show you how to derive powerful insights from your data, and format it in a way that lets you demonstrate them.

`glatos` can be used to get the residence index of your animals at all the different stations.
In fact, `glatos` offers five different methods for calculating Residence Index. For this lesson, we will showcase two of them, but more information on the others can be found in the `glatos` documentation.

The `residence_index()` function requires an events object to create a residence index. We will start by creating a subset like we did in the last lesson. This will save us some time, since running the residence index on the full set is prohibitively long for the scope of this workshop.

First we will decide which animals to base our subset on. To help us with this, we can use `group_by` on the events object to make it easier to identify good candidates.

~~~
#Using all the events data will take too long, so we will subset to just use a couple animals
events %>% group_by(animal_id) %>% summarise(count=n()) %>% arrange(desc(count))

#In this case, we have already decided to use these three animal IDs as the basis for our subset.
subset_animals <- c('PROJ59-1191631-2014-07-09', 'PROJ59-1191628-2014-07-07', 'PROJ64-1218527-2016-06-07')
events_subset <- events %>% filter(animal_id %in% subset_animals)

events_subset
~~~
{: .language-r}

Now that we have a subset of our events object, we can apply the `residence_index` functions.

~~~
# Calc residence index using the Kessel method

rik_data <- residence_index(events_subset,
                            calculation_method = 'kessel')
# "Kessel" method is a special case of "time_interval" where time_interval_size = "1 day"
rik_data

# Calc residence index using the time interval method, interval set to 6 hours
rit_data <- residence_index(events_subset,
                            calculation_method = 'time_interval',
                            time_interval_size = "6 hours")

rit_data
~~~
{: .language-r}

Although the code we've written for each method of calculating the residence index is similar, the different parameters and calculation methods mean that these will return different results. It is up to you to investigate which of the methods within `glatos` best suits your data and its intended application.


One of the development goals of the `glatos` package is interoperability with other scientific R packages. Currently, we can
'crosswalk' data from `glatos` data to the package [VTrack](https://github.com/RossDwyer/VTrack). By 'crosswalk', we mean that we can take data that has been manipulated and formatted by `glatos`, and make it usable by another package, in this case, VTrack. We'll use the same dataset as before, but we'll also add some related metadata from a different file and filter out all the detections that aren't from proj58. Again, we are making subsets of our data both to demonstrate how and to save ourselves some processing time.

First, let's get the tagging metadata.

~~~
tags <- prepare_tag_sheet('Tag_Metadata/Proj58_Metadata_cownoseray.xlsx',sheet = 2, start = 5)
~~~
{: .language-r}

We'll filter out all the detections that aren't part of proj58 and pull in the stations metadata file. We'll need this metadata because the format that VTrack is expecting requires deployment information. The `convert_otn_to_att` function in `glatos` will handle assembling the data as long as you pass it the correct deployment metadata. As always, if you have any further questions about the function, the documentation is always available.

~~~
# Filter our dets so we only have proj58 ones
proj58_detections <- detections_filtered %>%  filter(collectioncode == 'PROJ58')

?read_otn_deployments
deploys <- read_otn_deployments('matos_FineToShare_stations_receivers_202104091205.csv')
~~~
{: .language-r}

Now that we have all the pieces- detections, tags, and deployment metadata- we can run the `convert_otn_to_att` function, which will take the `glatos` data, in OTN format, and convert it into the ATT format, for VTrack.

~~~
?convert_otn_to_att

ATTdata <- convert_otn_to_att(proj58_detections, tags, deploymentObj = deploys)

# ATT is split into 3 objects, we can view them like this
ATTdata$Tag.Detections
ATTdata$Tag.Metadata
ATTdata$Station.Information
~~~
{: .language-r}

With this done, you can use your data with the VTrack package. You'll notice that not all the detections made it into the ATT object. That's because the conversion function only keeps detections which occur on receivers for which we have deployment metadata. Detections with no deployment metadata are excluded. This is to prevent issues with VTrack.

Now that our data is in a format that VTrack can understand, we can apply VTrack's functions to it. For example, we can call VTrack's abacusPlot function to generate an abacus plot of our data:

~~~
# Now that we have an ATT dataframe, we can use it in VTrack functions:

# Abacus plot:
VTrack::abacusPlot(ATTdata)
~~~
{: .language-r}

This is not especially exciting, since we've done plenty of abacus plots already. However, VTrack has its own set of unique features, just like `glatos`. To use the spacial features of VTrack, however, we have to give the ATT object a coordinate system to use.

~~~
# If you're going to do spatial things in ATT:
library(rgdal)
# Tell the ATT dataframe its coordinates are in decimal lat/lon
proj <- CRS("+init=epsg:4326")
attr(ATTdata, "CRS") <-proj
~~~
{: .language-r}

Once that's done, we can use VTrack's functions on our dataset. For example, the `COA` function, which calculates your dataset's Centers of Activity, can be used like this:

~~~
?COA
coa <- VTrack::COA(ATTdata)
coa
~~~
{: .language-r}

To see what this brings us, let's take a look at a plot of the COAs from VTrack. We'll use animal 'PROJ58-1218518-2015-09-16 for this.

~~~
# Plot a COA
coa_single <- coa %>% filter(Tag.ID == 'PROJ58-1218518-2015-09-16')

# We'll use raster to get the polygon
library(raster)
USA <- getData('GADM', country="USA", level=1)
MD <- USA[USA$NAME_1=="Maryland",]

# plot the object and zoom in to lake Huron. Set colour of ground to green Add labels to the axises
plot(MD, xlim=c(-77, -76), ylim=c(38, 40), col='green', xlab="Longitude", ylab="Latitude")

# For much more zoomed in plot
# plot(MD, xlim=c(-76.75, -76.25), ylim=c(38.75, 39), col='green', xlab="Longitude", ylab="Latitude")

# Create a palette
color <- c(colorRampPalette(c('pink', 'red'))(max(coa_single$Number.of.Detections)))

#add the points

points(coa_single$Longitude.coa, coa_single$Latitude.coa, pch=19, col=color[coa_single$Number.of.Detections],
    cex=log(coa_single$Number.of.Stations) + 0.5) # cex is for point size. natural log is for scaling purposes


# add axises and title
axis(1)
axis(2)
title("Centers of Activities for PROJ58-1218518-2015-09-16")
~~~
{: .language-r}

For even more data processing functions, here's an example of `dispersalSummary`, which calculates your dataset's metrics of dispersion.

~~~
# Dispersal information
# ?dispersalSummary
dispSum<-dispersalSummary(ATTdata)

View(dispSum)

# Get only the detections when the animal just arrives at a station
dispSum %>% filter(Consecutive.Dispersal > 0) %>%  View
~~~
{: .language-r}

This is only the beginning of what you can do with VTrack and its powerful suite of analysis functions, but a full lesson on VTrack is outside the scope of this workshop. We encourage you to look at the VTrack documentation to see what potential applications it might have to your data.

We will, however, continue with `glatos` for one more lesson, in which we will cover some basic, but very versatile visualization functions provided by the package.

## FACT Node

`glatos` has more advanced analytic tools that let you manipulate your data further. We'll cover a few of these features now, to show you how to take your data beyond just filtering and event creation. We'll also show you how to move your data from `glatos` to VTrack, another powerful suite of data manipulation tools. By combining the `glatos` package's powerful built-in functions with its interoperability across scientific R packages, we'll show you how to derive powerful insights from your data, and format it in a way that lets you demonstrate them.

`glatos` can be used to get the residence index of your animals at all the different stations.
In fact, `glatos` offers five different methods for calculating Residence Index. For this lesson, we will showcase two of them, but more information on the others can be found in the `glatos` documentation.

The `residence_index()` function requires an events object to create a residence index. We will start by creating a subset like we did in the last lesson. This will save us some time, since running the residence index on the full set is prohibitively long for the scope of this workshop.

First we will decide which animals to base our subset on. To help us with this, we can use `group_by` on the events object to make it easier to identify good candidates.

~~~
#Using all the events data will take too long, so we will subset to just use a couple animals
events %>% group_by(animal_id) %>% summarise(count=n()) %>% arrange(desc(count))

#In this case, we have already decided to use these three animal IDs as the basis for our subset.
subset_animals <- c('TQCS-1049274-2008-02-28', 'TQCS-1049271-2008-02-28', 'TQCS-1049258-2008-02-14')
events_subset <- events %>% filter(animal_id %in% subset_animals)

events_subset
~~~
{: .language-r}

Now that we have a subset of our events object, we can apply the `residence_index` functions.

~~~
# Calc residence index using the Kessel method

rik_data <- residence_index(events_subset,
                            calculation_method = 'kessel')
# "Kessel" method is a special case of "time_interval" where time_interval_size = "1 day"
rik_data

# Calc residence index using the time interval method, interval set to 6 hours
rit_data <- residence_index(events_subset,
                            calculation_method = 'time_interval',
                            time_interval_size = "6 hours")

rit_data
~~~
{: .language-r}

Although the code we've written for each method of calculating the residence index is similar, the different parameters and calculation methods mean that these will return different results. It is up to you to investigate which of the methods within `glatos` best suits your data and its intended application.


One of the development goals of the `glatos` package is interoperability with other scientific R packages. Currently, we can
'crosswalk' data from `glatos` data to the package [VTrack](https://github.com/RossDwyer/VTrack). By 'crosswalk', we mean that we can take data that has been manipulated and formatted by `glatos`, and make it usable by another package, in this case, VTrack. We'll use the same dataset as before, but we'll also add some related metadata from a different file.

First, let's get the tagging metadata.

~~~
?prepare_deploy_sheet

tags <- prepare_tag_sheet('TQCS_metadata_tagging.xlsx',sheet_name=1, header_line = 1)
receivers <- prepare_deploy_sheet('TEQ_Deployments_201001_201201.xlsx', sheet_name = 1, header_line = 0)
~~~
{: .language-r}

We'll need this TEQ metadata because the format that VTrack is expecting requires deployment information. The `convert_otn_to_att` function in `glatos` will handle assembling the data as long as you pass it the correct deployment metadata. As always, if you have any further questions about the function, the documentation is always available.

Because of differences with how the FACT data is formatted, we need to use `prepare_deploy_sheet` rather than `read_otn_deployments`. Depending on how much data you import and from how many sources, you may see both of these functions. More information on how they work and what they do can, as always, be found in the `glatos` documentation and help files. For now, it is enough to know that they are two different ways of doing the same thing- preparing receiver metadata for an OTN-format to ATT-format conversion- and which one to use depends on the format of your data. For FACT data, we use `prepare_deploy_sheet`.

We also need to quickly add some columns that FACT extracts do not have, since VTrack will look for them. Remember, the syntax for creating and filling a blank column in your dataframe is the same square-bracket syntax we covered in the earliest parts of this workshop. We also have to rename the station names in our receivers object so that they match the format of the station names in our detections object.

~~~
#Add columns missing from FACT extracts.
detections_filtered['sensorvalue'] = NA
detections_filtered['sensorunit'] = NA

# Rename the station names in receivers to match station names in detections
receivers <- receivers %>% mutate(station=substring(station, 4))
~~~
{: .language-r}

Now that we have all the pieces- detections, tags, and deployment metadata- we can run the `convert_otn_to_att` function, which will take the `glatos` data, in OTN format, and convert it into the ATT format, for VTrack.

~~~
?convert_otn_to_att

ATTdata <- convert_otn_to_att(detections_filtered, tags, deploymentSheet = receivers)

# ATT is split into 3 objects, we can view them like this
ATTdata$Tag.Detections
ATTdata$Tag.Metadata
ATTdata$Station.Information
~~~
{: .language-r}

With this done, you can use your data (now in the `ATTdata` object) with the VTrack package. You may notice that not all the detections made it into the ATT object. That's because the conversion function only keeps detections which occur on receivers for which we have deployment metadata. Detections with no deployment metadata are excluded. This is to prevent issues with VTrack.

Now that our data is in a format that VTrack can understand, we can apply VTrack's functions to it. For example, we can call VTrack's abacusPlot function to generate an abacus plot of our data:

~~~
# Now that we have an ATT dataframe, we can use it in VTrack functions:

# Abacus plot:
VTrack::abacusPlot(ATTdata)
~~~
{: .language-r}

This is not especially exciting, since we've done plenty of abacus plots already. However, VTrack has its own set of unique features, just like `glatos`. To use the spacial features of VTrack, however, we have to give the ATT object a coordinate system to use.

~~~
# If you're going to do spatial things in ATT:
library(rgdal)
# Tell the ATT dataframe its coordinates are in decimal lat/lon
proj <- CRS("+init=epsg:4326")
attr(ATTdata, "CRS") <-proj
~~~
{: .language-r}

Once that's done, we can use VTrack's functions on our dataset. For example, the `COA` function, which calculates your dataset's Centers of Activity, can be used like this:

~~~
#Calculate centers of activity.
?COA
coa <- VTrack::COA(ATTdata)

coa %>% group_by(Tag.ID) %>% summarize(n())
coa
~~~
{: .language-r}

To see what this brings us, let's take a look at a plot of the COAs from VTrack. We'll use animal 'TQCS-1049273-2008-02-28' for this.

We also need to get a shapefile for the Florida coastline so that we have something onto which we plot our data. At the time of this workshop, we've had some problems connecting to the GADM service from which we get this shapefile. We encourage you to try it as presented in the code. If that doesn't work, however, you can still get the shapefile this way:

- Go to `http://biogeo.ucdavis.edu/data/gadm3.6/Rsp/gadm36_USA_1_sp.rds`. Your browser should download a file called `gadm36_USA_1_sp.rds`.
- Navigate to the file in your file explorer and get the path.
- In RStudio, navigate to the console and run the command `USA <- readRDS('/file/path/to/gadm36_USA_1_sp.rds')`

You should now be able to continue the code from the line `FL <- USA[USA$NAME_1=="Florida",]`.

~~~
# Plot a COA
coa_single <- coa %>% filter(Tag.ID == 'TQCS-1049273-2008-02-28')

# We'll use raster to get the polygon
library(raster)
USA <- getData('GADM', country="USA", level=1)
FL <- USA[USA$NAME_1=="Florida",]

# plot the object and zoom in to the St. Lucie River and Jupiter Inlet. Set colour of ground to green Add labels to the axises
plot(FL, xlim=c(-80.75, -80), ylim=c(27, 27.5), col='green', xlab="Longitude", ylab="Latitude")

# For much more zoomed in plot
# plot(FL, xlim=c(-80.4, -80.0), ylim=c(27, 27.3), col='green', xlab="Longitude", ylab="Latitude")

# Create a palette
color <- c(colorRampPalette(c('pink', 'red'))(max(coa_single$Number.of.Detections)))

#add the points

points(coa_single$Longitude.coa, coa_single$Latitude.coa, pch=19, col=color[coa_single$Number.of.Detections],
    cex=log(coa_single$Number.of.Stations) + 0.5) # cex is for point size. natural log is for scaling purposes


# add axises and title
axis(1)
axis(2)
title("Centers of Activities for TQCS-1049273-2008-02-28")
~~~
{: .language-r}

For even more data processing functions, here's an example of `dispersalSummary`, which calculates your dataset's metrics of dispersion.

~~~
# Dispersal information
# ?dispersalSummary
dispSum<-dispersalSummary(ATTdata)

View(dispSum)

# Get only the detections when the animal just arrives at a station
dispSum %>% filter(Consecutive.Dispersal > 0) %>%  View
~~~
{: .language-r}

This is only the beginning of what you can do with VTrack and its powerful suite of analysis functions, but a full lesson on VTrack is outside the scope of this workshop. We encourage you to look at the VTrack documentation to see what potential applications it might have to your data.

We will, however, continue with `glatos` for one more lesson, in which we will cover some basic, but very versatile visualization functions provided by the package.
