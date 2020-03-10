---
title: Basic Visualization and Plotting
teaching: 30
exercises: 0
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
            main='NSBS Detections By Station') # can use plot() variables here, they get passed thru to plot()
~~~
{: .language-r}

This is good, but cluttered. We can also filter out a single animal ID and plot
only the abacus plot for that.
~~~
# pick a single fish to plot
abacus_plot(detections_filtered[detections_filtered$animal_id== "NSBS-Alison",],
            location_col='station',
            main="NSBS-Alison Detections By Station")
~~~
{: .language-r}


Additionally, if we only wanted to plot for a subset of receivers, we could do That
as well, using the following code to isolate a particular subset. This is less useful for our
Blue Shark dataset, and more applicable to a dataset structured like GLATOS, where the
glatos_array column would link multiple receivers together into an array, which we could
then select on. In this case, we're only using our stations, so it's less important.
~~~
# subset of receivers?

receivers

receivers_subset <- receivers[receivers$station %in% c('HFX005', 'HFX031', 'HFX040'),]
receivers_subset

det_first <- min(detections$detection_timestamp_utc)
det_last <- max(detections$detection_timestamp_utc)
receivers_subset <- receivers_subset[
  receivers_subset$deploy_date_time < det_last &
    receivers_subset$recover_date_time > det_first &
    !is.na(receivers_subset$recover_date_time),] #removes deployments without recoveries

locs <- unique(receivers_subset$station)

locs
~~~
{: .language-r}

In keeping with earlier lessons, we could also do the same selection using dplyr's
filter() method.
~~~
receivers

receivers_subset <- receivers[receivers$station %in% c('HFX005', 'HFX031', 'HFX040'),]
receivers_subset

det_first <- min(detections$detection_timestamp_utc)
det_last <- max(detections$detection_timestamp_utc)

receivers_subset <- filter(receivers_subset, deploy_date_time < det_last &
                             recover_date_time > det_first &
                             !is.na(receivers_subset$recover_date_time))

receivers_subset
~~~
{:.language-r}

Note that the row indices are different- filter automatically resets them to 1-3,
whereas selecting them with base R preserves the original numbering. Use whichever
best suits your needs.

We can also plot abacus plots with receiver histories, which can give us a better idea of in
which order our tracked fish travelled through our receivers. We just have to pass
a few extra parameters to the abacus plot function, including our receivers array
so that it builds out the history.

Note that we must add a glatos_array column to receivers before we can plot it
in this way- the function still expects GLATOS data. For our purposes, it is enough
to use the station column, but different variables may suit your data differently.
~~~
# Abacus Plots w/ Receiver History ####
# Using the receiver data frame from the start:
# See the receiver history behind the detections to know what you could see.

receivers$glatos_array = receivers$station

abacus_plot(detections_filtered[detections_filtered$animal_id == 'NSBS-Hooker',],
            pch = 16,
            type='b',
            receiver_history=receivers,
            location_col = 'station')
~~~
{: .language-r}

If we want to see actual physical distribution, a bubble plot will serve us better.
(Add part for generating the NS map)
With the map generated, we can pass it to the bubble plot and see the results.
~~~
# Bubble Plots for Spatial Distribution of Fish ####
# bubble variable gets the summary data that was created to make the plot
detections_filtered
bubble <- detection_bubble_plot(detections_filtered,
                                location_col = 'station',
                                map = NS,
                                col_grad=c('white', 'green'),
                                background_xlim = c(-66, -62),
                                background_ylim = c(42, 46))
~~~
{: .language-r}

There are additional customisations we can perform, which let us tune the output of the
bubble plot function to better suit our needs. A few of the parameters are demonstrated
below, but we encourage you to investigate the documentation and see what suits Your
needs.
~~~
# more complex example including zeroes by adding a specific
# receiver locations dataset, in this case the receivers dataset above.

bubble_custom <- detection_bubble_plot(detections_filtered,
                                       location_col='station',
                                       map = NS,
                                       background_xlim = c(-63.75, -63.25),
                                       background_ylim = c(44.25, 44.5),
                                       symbol_radius = 0.7,
                                       receiver_locs = receivers,
                                       col_grad=c('white', 'green'))
~~~
{: .language-r}
