---
title: More Features of GLATOS
teaching: 15
exercises: 0
questions:
    - "What other features does GLATOS offer?"
---

GLATOS has some more advanced analystic tools beyond filtering and creating events.

GLATOS can be used to get the residence index of your animals at all the different stations.
GLATOS offers 5 different methods for calculating Residence Index, here we will showcase 2 of those.
residence_index requires an events objects to create a residence_index, we will use a subset the one
from the last lesson.

First we will figure out which animals to subset. We will use `group_by` on the events object to find some good candidates.

~~~
#Using all the events data will take too long, we will subset to just use a couple animals
events %>% group_by(animal_id) %>% summarise(count=n()) %>% arrange(desc(count))

subset_animals <- c('PROJ59-1191631-2014-07-09', 'PROJ59-1191628-2014-07-07', 'PROJ64-1218527-2016-06-07')
events_subset <- events %>% filter(animal_id %in% subset_animals)

events_subset
~~~
{: .language-r}

Now with the subsetted events objects, lets look at the functions.

~~~
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
~~~
{: .language-r}

Both of these methods are similar and will almost always give different results, you can 
explore them all to see what method works best for your data.


GLATOS strives to be interoperable with other scientific R packages. Currently, we can 
crosswalk GLATOS data over to the package [VTrack](https://github.com/RossDwyer/VTrack). 
We'll use the same dataset as before, but we'll also pull in some other metadata and filter
out all non-proj58 detections.

First, lets get the tagging metadata. Some of the release timestamps are formated wrong
so we will fix that just like in the earlier lessons

~~~
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
~~~
{: .language-r}

We'll filter out all the detections that aren't part of proj58 and pull in the stations metadata file.

~~~
# Filter our dets so we only have proj58 ones
proj58_detections <- detections_filtered %>%  filter(collectioncode == 'PROJ58')

?read_otn_deployments
deploys <- read_otn_deployments('matos_FineToShare_stations_receivers_202104091205.csv')
~~~
{: .language-r}

Now that we have all the pieces, we can run the conversion function.
~~~
?convert_otn_to_att

ATTdata <- convert_otn_to_att(proj58_detections, tags, deploymentObj = deploys)

# ATT is split into 3 objects, we can view them like this
ATTdata$Tag.Detections
ATTdata$Tag.Metadata
ATTdata$Station.Information
~~~
{: .language-r}

And then you can use your data with the VTrack package. You'll notice that not all the detections made it into the ATT object. That's because the conversion function only keeps detections that it has station metadata for. Tags with no detections will also be thrown out by the function. This is to prevent issues
with VTrack.

You can call its abacusPlot function to generate an abacus plot:
~~~
# Now that we have an ATT dataframe, we can use it in VTrack functions:

# Abacus plot:
VTrack::abacusPlot(ATTdata)
~~~
{: .language-r}

To use the spacial features of VTrack, we have to give the ATT object a coordinate system to use.
~~~
# If you're going to do spatial things in ATT:
library(rgdal)
# Tell the ATT dataframe its coordinates are in decimal lat/lon
proj <- CRS("+init=epsg:4326")
attr(ATTdata, "CRS") <-proj
~~~
{: .language-r}

Here's an example of the Centers of Activity function from VTrack.
~~~
?COA
coa <- VTrack::COA(ATTdata)
coa
~~~
{: .language-r}

Let's take a look at a plot of the COAs from VTrack. We'll use animal 'PROJ58-1218518-2015-09-16 for this.

~~~
# Plot a COA
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
~~~
{: .languege-r}

Here's an example of a VTrack function for getting metrics of dispersal.
~~~
# Dispersal information
# ?dispersalSummary
dispSum<-dispersalSummary(ATTdata)

View(dispSum)

# Get only the detections when the animal just arrives at a station
dispSum %>% filter(Consecutive.Dispersal > 0) %>%  View
~~~
{: .language-r}

VTrack has some more analysis functions like creating activity space models.

GLATOS also includes tools for planning receiver arrays, simulating fish moving in an array, 
and some nice visualizations (which we will cover in the next episode).

