---
title: Introduction to GLATOS and Spatial Mapping
teaching: 30
exercises: 0
---
## Spatial Data
We can use GLATOS to make a variety of useful maps by combining our GLATOS data with another library, sp (spatial). This requires us to manipulate the data in some new ways, but gives us more options when it comes to plotting our data.

First, we need to translate our GLATOS data into a spatially-aware dataframe. The sp library has some methods that can help us do this. However, we unfortunately can't run them directly on the GLATOS dataframe. GLATOS stores data as a "glatos_detections" class (you can see this by running class(your-detections-dataframe)), and though it extends data.frame, some R methods do not operate on this object. However, we can get around this with some straightforward object type casting.

First, we start by importing the libraries we will need to use.

~~~
library(glatos) # Our main GLATOS library.
library(mapview) # We'll use this for slippy map plotting
library(sp) # Our spatial library
library(spdplyr) # A version of dplyr that allows us to work with spatial data
library(lubridate) # For manipulating dates later
~~~
{: .language-r}

Now we'll pull in our data. For the purposes of this workshop, we'll use the walleye test data included with GLATOS.

~~~
det_file <- system.file("extdata", "walleye_detections.csv", package = "glatos")
detections <- read_glatos_detections(det_file=det_file)

#Print the first few rows to check that it came in alright.
head(detections)
~~~
{: .language-r}

This should give us a glatos_detections dataframe including all our walleye data. To start the process of making a spatial object, we're going to extract the latitude and longitude columns using the 'select' function we've already covered.

~~~
lat_long <- detections %>% select(deploy_long, deploy_lat)
lat_long
~~~
{: .language-r}

Make sure to select the columns in the order longitude, latitude. This is how many functions expect to receive the data and it can cause problems if you order them in the opposite direction.

Now that we have an object containing just the latitude and longitude, we can use our Spatial library to convert these to a spatially-aware object.

~~~
transformed_latLong <- SpatialPoints(as.data.frame(lat_long), CRS("+init=epsg:4326"))
#We cast lat_long to a dataframe because it is still a glatos_detections dataframe.
#CRS is our coordinate reference system.
transformed_latLong
~~~
{: .language-r}

This gives us a spatially aware set of latitudes and longitudes that we can now attach to our original dataframe. We can do this with the SpatialPointsDataFrame method, which takes coordinates and a dataframe and returns a SpatialPointsDataFrame object.

~~~
spdf <- SpatialPointsDataFrame(transformed_latLong, as.data.frame(detections))
#Once again we're casting detections directly to a standard dataframe.
spdf
~~~
{: .language-r}

The variable spdf now contains spatial data as well as all of the data we originally had. This lets us plot it without any further manipulation using the mapview function from the library of the same name.

~~~
mapview(spdf)
~~~
{: .language-r}

This will open in a browser window, and will give you a slippy map that lets you very quickly visualize your data in an interactive setting. If, however, you want to plot it in the default way to take advantage of the options there, that works too- the 'points' function will accept our spatially aware dataframe.

~~~
plot(greatLakesPoly, col = "grey")
#greatLakesPoly is a shapefile included with the glatos library that outlines the Great Lakes.

points(deploy_lat ~ deploy_long, data = spdf, pch = 20, col = "red",
       xlim = c(-66, -62))
~~~
{: .language-r}

We can also use the spdplyr library to subset and slice our spatially-aware dataset, allowing us to pass only a subset- say, of a single animal- to mapview (or alternative plotting options).

~~~
mapview(spdf %>% filter(animal_id == 153)) #Plot only the points that correspond to the fish with the animal_id 153.
~~~
{: .language-r}

We could also subset along time, returning to the lubridate function we've already covered.

~~~
mapview(spdf %>% mutate(detection_timestamp_utc = ymd_hms(detection_timestamp_utc)) %>%
          filter(detection_timestamp_utc > as.POSIXct("2012-05-01") & detection_timestamp_utc < as.POSIXct("2012-06-01")))
~~~
{: .language-r}

All of these options let us map and plot our data in a spatially-aware way.

If you want to investigate these options further, mapview and spdplyr are both extensively documented, allowing you to fine-tune your plots to suit your needs. Mapview's documentation is available at [this page](https://r-spatial.github.io/mapview/index.html), and links to additional spdplyr references can be found [at its CRAN page.](https://cran.r-project.org/web/packages/spdplyr/index.html)
