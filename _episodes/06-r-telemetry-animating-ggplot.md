---
title: Interactive Exploration of Data / Animating ggplot with gganimate and gifski
teaching: 10
exercises: 0
questions:
        - "How can I explore my data interactively"
        - "How can I avoid 'overplotting' my data when performance is a factor?"
        - "How do I animate my tracks?"
objectives:
        - "Isolate one individual and animate his paths between receivers using gganimate and gifski."
---

### Interactive Data exploration with `mapview`
##### with spatial data subsetting via `spdplyr`!

A couple of quick and exciting packages for exploring and manipulating spatial datasets I wanted to mention quickly so you could explore on your own data. First, `mapview`, which launches a tiled slippy-map with your data objects projected onto it for you. Here we will hand it the spatial data object we made earlier, `stS`, and without telling mapview anything about it, we'll get a map we can interact with in our browser.


~~~
# Exploring spatial data interactively

library(mapview)  # generates 'slippy' maps from spatial data frames
library(spdplyr)  # this is a bit of a new package, 
                  # this will let us keep our spatial data frame 
                  # and still explore the data in the tidyverse way!



# How long would plotting all of this take? 
# A long time! And the resulting browser window will be overloaded and
# non-functional. So don't pass -too- many points to mapview!

# don't run this!
# mapview(stS)
~~~
{: .language-r}

But wait, our browser won't be very happy with us throwing 1.5m points at it. We'd better subset! but how to subset a spatial data object? With a new package called `spdplyr`, author Michael Sumner is implementing dplyr 'verbs' on spatial dataframes. So we'll use both `mapview` and `spdplyr` together for a quick example.

~~~
# Instead, how could we look at a single animal? 
mapview(stS %>% filter(tag.ID == "A69-1601-30617"))
# 18,000 rows of data
# Quick and snappy.
~~~
{: .language-r}

That isn't too much data yet. let's see about all the data points over a given time period, say a month.

~~~
# A single month?  # 100,000 rows of data, at the edge of what mapview can do comfortably
# Plotting this one takes a little longer, and the plot may be very slow to interact!
mapview(stS %>% mutate(DateTime = ymd_hms(DateTime)) %>% 
                filter(DateTime > as.POSIXct("2012-05-01") & DateTime < as.POSIXct("2012-06-01")))
~~~
{: .language-r}

Q: Since we don't have the ability to represent time, what are some optimal subsetting strategies for presenting data to `mapview()`?


Q: How could you confirm how big a subset of your data will be before you pass it to a plotting or analysis function?

Don't forget: Investigate how big a dataset you're going to pass to a tool like mapview! Try not to 'over-plot' too many data points on top of one another in a static plot!


### Animating Plots

You can extend `ggplot` with `gganimate` to generate multiple plots, and stitch them together into an animation. In the `glatos` package, we'll use ffmpeg to make videos out of these static images, but you can also generate a gif using `gifski`.

~~~
## Animating plots ####

# Let's pick one animal to follow
st1<-st_summary %>% filter(tag.ID=="A69-1601-30617") 

an1<-bgo %>%
  fortify %>%
  ggplot(aes(x, y, fill=z))+
  geom_raster()+
  scale_fill_etopo()+
  labs(x="Longitude", y="Latitude", fill="Depth")+
  theme_classic()+
  theme(legend.key.width=unit(5, "cm"), legend.position="top")+
  theme(legend.position="top")+
  geom_point(data=st_summary %>%
               as_tibble() %>%
               distinct(lon, lat),
             aes(lon, lat), inherit.aes=F, pch=21, fill="red", size=2)+
  geom_point(data=st1 %>% filter(tag.ID=="A69-1601-30617"),
             aes(lon, lat), inherit.aes=F, colour="purple", size=5)+ # from here, this plot is not an animation yet. an1
  transition_time(date(st1$dt))+
  labs(title = 'Date: {frame_time}')  # Variables supplied to change with animation.

~~~
{: .language-r}

Now that we have the plots in an1, we can animate them by handing them to `gganimate::animate()`

~~~
# an1 is now a list of plot objects but we haven't plotted them.

?gganimate::animate  # To go deeper into gganimate's animate function and its features.

gganimate::animate(an1)

~~~
{: .language-r}


Notably: our fish is doing a lot of portage! The perils of working in a winding river system, or around land masses is that our straight-line interpolations plain look silly when you animate them this way.

Later we'll use the `glatos` package to help us dodge land masses better in our transitions.
