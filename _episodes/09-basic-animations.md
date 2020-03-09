---
title: Basic Visualization and Plotting
teaching: 0
exercises: 0
---

With just a little extra code, we can go from static visualizations right into animations
with the functionality provided by the glatos package.

First, we need to import a couple more libraries that will let us manipulate polygons and raster objects. With those, we'll be able to build a map for our plot.

~~~
library(sp) #for loading greatLakesPoly
library(raster) #for raster manipulation (e.g., crop)
~~~
{:.language-r}

We'll also re-use our shapefile of the NS coastline from earlier.
~~~
Canada <- getData('GADM', country="CAN", level=1)
NS <- Canada[Canada$NAME_1=="Nova Scotia",]
~~~
{:.language-r}

For the purposes of this workshop, we'll only track one fish. You can select a single fish's detections in a certain timeframe with the code below, changing the dates and animal IDs as befits your data.

~~~
# extract one fish and subset date ####
det <- detections[detections$animal_id == 'NSBS-Hooker' &
             detections$detection_timestamp_utc > as.POSIXct("2014-01-01") &
             detections$detection_timestamp_utc < as.POSIXct("2014-12-31"),]
~~~
{:.language-r}

The polygon we've loaded is quite large, so we want to crop it down to a more reasonable area. Otherwise, we run the risk that our code will time out, exhaust RStudio's memory allocation, or just take too long to be practical. We can use the crop() function, and pass it our polygon, and a lon/lat extent to crop to- in this case, we'll get an area around Halifax Harbour, where our detections were picked up.

~~~
# crop polygon to just outside Halifax Harbour ####
halifax <-  crop(NS, extent(-66, -62, 42, 45))
~~~
{:.language-r}

Now that we have a polygon representing the appropriate area, we can plot it. We also want to put our points representing our fish detections n the plot, which we can do with the points() function.

~~~
plot(halifax, col = "grey")
points(deploy_lat ~ deploy_long, data = det, pch = 20, col = "red",
       xlim = c(-66, -62))
~~~
{:.language-r}

That might look OK, but if we're going to animate it, we need more- since we need to be able to interpolate the paths points to properly make the animation, we need to know if our interpolations make any sense. To do that, we need to know whether our paths cross land at any point. And to do that, we need to know what on our map is water, and what on our map is land. Fortunately, glatos lets us do this with the make_transition() function.

make_transition generates two objects- a transition layer, and a raster object, both representing the land and water on the map we're plotting on. However, take note! Since glatos was originally designed to run on data from lakes, it will treat any fully-bounded polygon as a lake. This means that depending on your shapefile, glatos may mistake your land for water, and vice-versa!

Fortunately, we can get around this. make_transition takes a parameter, 'invert', that defaults to false. If it is true, then make_transition() will return the inverse of the raster it otherwise would have returned. If it is treating your land masses as water, this should fix the problem.

~~~
tran <- make_transition_flipped(halifax, res = c(0.1, 0.1))
~~~
{:.language-r}

Finally, we have our transition layer and our raster. Let's plot it against our polygon and see how it looks.

~~~
plot(tran$rast, xlim = c(-66, -62), ylim = c(42, 45))
plot(halifax, add = TRUE)
~~~
{:.language-r}

That doesn't look great- the resolution isn't very high, and the water area (green by default) definitely doesn't match up with the coastline. We can re-run make_transition with a higher resolution, however, to provide a better match.

~~~
# not high enough resolution- bump up resolution
tran1 <- make_transition_flipped(halifax, res = c(0.001, 0.001))
~~~
{:.language-r}

Keep in mind that increasing the resolution will make the function take a longer time to run, and on large polygons, the operation can time out. It's up to you to find the right balance of speed and detail as appropriate for your dataset.

~~~
# plot to check resolution- much better
plot(tran1$rast, xlim = c(-66, -62), ylim = c(42, 45))
plot(halifax, add = TRUE)
~~~
{:.language-r}

Much better!

The next step is to add our points to the map. For this, we'll break out the unique lat/lon pairs from our data and only plot those. That will cut down on the size of the data set we're adding and make our rendering speedier.

~~~
# add fish detections to make sure they are "on the map"
# plot unique values only for simplicity
foo <- unique(det[, c("deploy_lat", "deploy_long")])
points(foo$deploy_long, foo$deploy_lat, pch = 20, col = "red")
~~~
{:.language-r}

We're finally ready to interpolate our points, which we can do with the interpolate_path() function. We pass it our detections, our transition layer, and a specification for how it should output its results- in this case, as a data.table. This may not be right for your dataset, so be sure to check.

~~~
# call with "transition matrix" (non-linear interpolation), other options ####
# note that it is quite a bit slower due than linear interpolation
pos2 <- interpolate_path(det, trans = tran1$transition, out_class = "data.table")
~~~
{:.language-r}

At last, we can do a quick sanity check, plotting our interpolated data against our map and making sure all our points are in the right place- that is, the water.

~~~
plot(halifax, col = "grey")
points(latitude ~ longitude, data = pos2, pch=20, col='red', cex=0.5)
~~~
{:.language-r}

We're finally ready to generate our animation. Using the make_frames function, we can generate, at once, a series of still frames representing the animation, and the animation itself.

Note that we have to pass some extra parameters to the make_frames() function. Since glatos was written for the Great Lakes, by default it will use those as its background and lat/lon. We can change the former with bg_map, which we set as the 'halifax' object we've been using, and background_xlim and background_ylim to set the lon/lat properly- otherwise, even if we have the right map, our dots won't display.

We also have 'overwrite' set to TRUE, which just means that if the files already exist, they'll be overwritten. That's fine here, but you may want to set yours differently.

~~~
# Make frames out of the data points ####
# ?make_frames

# just gimme the animation!
#setwd('~/code/glatos')
frameset <- make_frames(pos2, bg_map=halifax, background_ylim = c(42, 45), background_xlim = c(-66, -62), overwrite=TRUE)
~~~
{:.language-r}

Excellent! A brief but accurate animation of our data points.

You may find glatos' animation options restrictive, or might not like the output they generate. If that's the case, you can set the 'animate' parameter to FALSE and just get the frames, which you can then take into your own animation software to tweak as you see fit. You can also supply an out_dir to specify where the animations and frames get written to, if you want it to be somewhere other than your working directory.

~~~
# can set animate = FALSE to just get the composite frames
# to take into your own program for animation
#

pos1 <- interpolate_path(det)
frameset <- make_frames(pos1, bg_map=halifax, background_ylim = c(42, 45), background_xlim = c(-66, -62), out_dir=paste0(getwd(),'/anim_out'), overwrite=TRUE)
~~~
{:.language-r}
