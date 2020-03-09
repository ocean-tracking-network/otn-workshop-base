---
title: More Tidyverse functions useful for telemetry data analysis
teaching: 15
exercises: 0
questions:
      - "What dplyr functions are useful to analyze my data?"
      - "What are some example workflows for analyzing telemetry datasets"
objectives:
      - "Learn to create new metrics from the base data using dplyr."
      - "Create and plot our summary statistics, or save them to new columns and use them in further calculations."

---

Now that we have an idea of what an exploratory workflow might look like with Tidyverse libraries like `dplyr` and `ggplot2`, let's look at how we might implement a common telemetry tidying workflow using these tools.

~~~
# Filtering and data processing

st<-as_tibble(st) # make sure st is a tibble again for speed's sake

# One pipe to fix dates,
# filter subsets,
# calculate lead and lag locations,
# and calculate new derived values, in this case, bearing and distance.

st<-st %>%  # overwrite the dataframe with the result of this pipe!
  mutate(dt=ymd_hms(DateTime)) %>%
  dplyr::select(-1, -2, -DateTime) %>%  # Don't return DateTime, or column 1 or 2 of the data
 # filter(month(dt)>5 & month(dt)<10) %>%  # filter for just a range of months?
  arrange(dt) %>%
  group_by(tag.ID) %>%
  mutate(llon=lag(lon), llat=lag(lat)) %>%  # lag longitude, lag latitude (previous position)
  filter(lon!=lag(lon)) %>%  # If you didn't change positions, drop this row.
  rowwise() %>%
  filter(!is.na(llon)) %>%  # Also drop any NA lag longitudes (i.e. the first detection of each)
  mutate(bearing=argosfilter::bearing(llat, lat, llon, lon)) %>% # use mutate and argosfilter to add bearings!
  mutate(dist=argosfilter::distance(llat, lat, llon, lon)) # use mutate and argosfilter to add distances!


View(st)
~~~
{: .language-r}

So there's a lot going on here. First, we're going to write the result of our pipe right back into the source dataset. This is good for saving memory, but bad for rapid reproducability/tinkering with the workflow. If we get it wrong, we have to go back and re-instantiate our dataset before trying again. So you may not want to jump to doing this right away.

 So in our pipe chain here, we are doing a lot of the things we saw earlier. We're fixing up the date object into a new column `dt` using `lubridate`. We're throwing out the first two columns, as well as the old `DateTime` string column. We're potentially filtering on `dt`, picking a range of months to keep. We're re-indexing the result with `arrange(dt)` before we start grouping to ensure that everything is in temporal order. We `group_by()` tag.ID, which is a stand-in for individual in this dataset. Then we use `mutate()` again within our grouped data along with `lag()` to produce new variables `llat` and `llon`. The `lag()` function operates on each group, grabbing the previous location (in time) for each animal, and storing it in two new columns. With this position and the previous position, we can calculate a distance and bearing between them. Now, this isn't a real distance or bearing for the trip between these points, that's not how acoustic detections work, we'll never say 'the animal traveled exactly X metres along this path between detections' but there might be a pattern to uncover using these measurements.

~~~
st %>%
  group_by(tag.ID) %>%
  mutate(cdist=cumsum(dist)) %>%
  ggplot(aes(dt, cdist, colour=tag.ID))+ geom_step()+
  facet_wrap(~Species) +
  guides(colour=F)
~~~
{: .language-r}

Now that we have our distance and bearing data, we can do things like calculate the total distance traveled per animal. Which as we mentioned, is more of a lower bound than a true measure, but especially in well-gated rivers could produce a useful metric.

~~~
st %>%
  filter(dist>2) %>%
  ggplot(aes(bearing, fill=Species))+
  # geom_histogram()+  # could do a histogram
  geom_density()+      # and/or a density plot
  facet_wrap(~Species) +  # one facet per species
  coord_polar()
~~~
{: .language-r}

This filter-and-plot by group removes all distances less than 2 (to take away movements within a multi-receiver gate, or multiple detections within the range of two adjacent receivers), and then creates a polar plot showing the dominant bearings for each individual. Because we're moving longitudinally within a river, we see a dominant east-west trend. And splitting on species shows us there may be differences in how they're using the river system. To prove a hypothesis like this to ourselves, we'd undergo a lot more filtering and individual-based analysis to see if any detection anomalies or hyper-active individuals are dominating the result.
