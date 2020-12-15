---
title: Basic Visualization and Plotting
teaching: 30
exercises: 0
questions:
    - "How can I use GLATOS to plot my data?"
    - "What kinds of plots can I make with my data?"
---

We can use GLATOS to quickly and effectively visualize our data, now that we've
cleaned it up.

One of the simplest ways is to use an abacus plot to display animal detections
against the appropriate stations.

~~~
# Visualizing Data - Abacus Plots ####
# ?glatos::abacus_plot
# customizable version of the standard VUE-derived abacus plots

abacus_plot(detections_w_events,
            location_col='station',
            main='TQCS Detections By Station') # can use plot() variables here, they get passed thru to plot()
~~~
{: .language-r}

This is good, but cluttered. We can also filter out a single animal ID and plot
only the abacus plot for that.
~~~
# pick a single fish to plot
abacus_plot(detections_filtered[detections_filtered$animal_id== "TQCS-1049258-2008-02-14",],
            location_col='station',
            main="TQCS-1049258-2008-02-14 Detections By Station")
~~~
{: .language-r}




If we want to see actual physical distribution, a bubble plot will serve us better.

Before we can plot this data properly, we need to download a shapefile of Florida
This will give us a map on which we can plot our data. We can get a suitable Shapefile
for Florida from GADM, the Global Administrative boundaries reference. The following
code will retrieve first the country, then the province/state:

~~~
library(raster)
library(sp)
USA <- getData('GADM', country="USA", level=1)
FL <- USA[USA$NAME_1=="Florida",]
~~~
{: .language-r}

With the map generated, we can pass it to the bubble plot and see the results.
~~~
# Bubble Plots for Spatial Distribution of Fish ####
# bubble variable gets the summary data that was created to make the plot
detections_filtered
bubble <- detection_bubble_plot(detections_filtered,
                                out_file = '../tqcs_bubble.png',
                                location_col = 'station',
                                map = FL,
                                col_grad=c('white', 'green'),
                                background_xlim = c(-81, -80),
                                background_ylim = c(26, 28))
~~~
{: .language-r}
