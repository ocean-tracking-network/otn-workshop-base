---
title: Network analysis using detections of animals at stations
teaching: 15
exercises: 5
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
as well, using the following code to isolate a particular receiver.
~~~
# subset of receivers?

receivers

receivers_subset <- receivers[receivers$station=='HFX005',]
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

(Have to revisit this after I talk with Ryan to see if it can be done. )
~~~
# Abacus Plots w/ Receiver History ####
# Using the receiver data frame from the start:
# See the receiver history behind the detections to know what you could see.

#Mutate new glatos_array column into the receivers.
receivers_with_ga <-
  receivers %>%
  mutate(glatos_array = receivers[station])

abacus_plot(detections_filtered[detections_filtered$animal_id == 'NSBS-Alison',],
            pch = 16,
            type='b',
            locations = sort(locs, decreasing = TRUE),
            receiver_history=receivers)
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
