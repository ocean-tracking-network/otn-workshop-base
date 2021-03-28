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
            main='Walleye Detection by Station') # can use plot() variables here, they get passed thru to plot()

abacus_plot(detections_w_events, 
            location_col='glatos_array', 
            main='Walleye Detection by Array') 

~~~
{: .language-r}

This is good, but cluttered. We can also filter out a single animal ID and plot
only the abacus plot for that.
~~~
# pick a single fish to plot
# pick a single fish to plot
abacus_plot(detections_filtered[detections_filtered$animal_id== "22",],
            location_col='station',
            main="Animal 22 Detections By Station")
~~~
{: .language-r}




If we want to see actual physical distribution, a bubble plot will serve us better.

The glatos package provides a raster of the Great Lakes to the bubble plot, we will just use that.
~~~
# Bubble Plots for Spatial Distribution of Fish ####
# bubble variable gets the summary data that was created to make the plot
detections_filtered

?detection_bubble_plot

bubble_station <- detection_bubble_plot(detections_filtered, 
                                location_col = 'station',
                                out_file = 'walleye_bubbles_by_stations.png')
bubble_station

bubble_array <- detection_bubble_plot(detections_filtered,
                                      out_file = 'walleye_bubbles_by_array.png')
bubble_array
~~~
{: .language-r}
