---
title: Basic Visualization and Plotting
teaching: 30
exercises: 0
questions:
    - "How can I use glatos to plot my data?"
    - "What kinds of plots can I make with my data?"
---

Now that we've cleaned and processed our data, we can use `glatos`' built-in plotting tools to make quick and effective visualizations out of it. One of the simplest visualizations is an abacus plot to display animal detections against the appropriate stations. To this end, `glatos` supplies a built-in, customizable `abacus_plot` function.

~~~
# Visualizing Data - Abacus Plots ####
# ?glatos::abacus_plot
# customizable version of the standard VUE-derived abacus plots


abacus_plot(detections_w_events,
            location_col='station',
            main='ACT Detections by Station') # can use plot() variables here, they get passed thru to plot()


~~~
{: .language-r}

This is good, but you can see that the plot is cluttered. Rather than plotting our entire dataset, let's try filtering out a single animal ID and only plotting that. We can do this right in our call to `abacus_plot` with the filtering syntax we've previously covered.

~~~
# pick a single fish to plot
abacus_plot(detections_filtered[detections_filtered$animal_id== "PROJ58-1218508-2015-10-13",],
            location_col='station',
            main="PROJ58-1218508-2015-10-13 Detections By Station")
~~~
{: .language-r}
In both of the above function calls, the argument 'main'

Other plots are available in `glatos` and can show different facets of our data. If we want to see the physical distribution of our stations, for example, a bubble plot will serve us better.

We'll continue to use the Maryland raster `MD` from last lesson. Remember that we need to provide a coastline shape to plot our data on top of.

~~~
# Bubble Plots for Spatial Distribution of Fish ####
# bubble variable gets the summary data that was created to make the plot
detections_filtered

?detection_bubble_plot

bubble_station <- detection_bubble_plot(detections_filtered,

                                        background_ylim = c(38, 40),
                                        background_xlim = c(-77, -76),
                                        map = MD,
                                        location_col = 'station',
                                        out_file = 'act_bubbles_by_stations.png')
bubble_station

bubble_array <- detection_bubble_plot(detections_filtered,
                                      background_ylim = c(38, 40),
                                      background_xlim = c(-77, -76),
                                      map = MD,
                                      out_file = 'act_bubbles_by_array.png')
bubble_array
~~~
{: .language-r}

These examples provide just a brief introduction to some of the plotting available in `glatos`.

> ## Glatos Challenge
>
> Challenge 1 ----
> Create a bubble plot of that bay we zoomed in earlier. Set the bounding box using the provided nw + se cordinates, change the colour scale and
> resize the points to be smaller. As a bonus, add points for the other receivers that don't have any detections.
> Hint: ?detection_bubble_plot will help a lot
> Here's some code to get you started
> ~~~
> nw <- c(38.75, -76.75) # given
> se <- c(39, -76.25) # given
> ~~~
> {: .language-r}
>
> > ## Solution
> >
> > ~~~
> > nw <- c(38.75, -76.75) # given
> > se <- c(39, -76.25) # given
> >
> > deploys <- read_otn_deployments('matos_FineToShare_stations_receivers_202104091205.csv') # For bonus
> > bubble_challenge <- detection_bubble_plot(detections_filtered,
> >                                      background_ylim = c(nw[1], se[1]),
> >                                      background_xlim = c(nw[2], se[2]),
> >                                      map = MD,
> >                                      symbol_radius = 0.75,
> >                                      location_col = 'station',
> >                                      col_grad = c('white', 'green'),
> >                                      receiver_locs = deploys, # For bonus
> >                                      out_file = 'act_bubbles_challenge.png')
> > ~~~
> > {: .language-r}
> > ![Bubble plot for detections on Lake Erie Stations](../Resources/act_bubbles_challenge.png)
> {: .solution}
{: .challenge}
