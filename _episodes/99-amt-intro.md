---
title: Introduction to AMT
teaching: 45
exercises: 0
questions: 
    - "What does the actel package do?"
    - "When should I consider using Actel to analyze my acoustic telemetry data?"

objectives:

keypoints:
---

`amt` (https://github.com/jmsigner/amt) is an R package designed to manage and analyze animal movement data. The functionality of 'amt' includes methods to calculate home ranges, track statistics (e.g. step lengths, speed, or turning angles), prepare data for fitting habitat selection analyses, and simulation of space-use from fitted step-selection functions.

Author: Jessica Robichaud

### Supplemental Resources

* [CRAN - `amt` Vignettes](https://cran.r-project.org/web/packages/amt/amt.pdf)
* [GitHub - `amt` package repository](https://github.com/jmsigner/amt)
* [YouTube - Josh Cullen using AMT to estimate space use with Kernel Density Estimation](https://youtu.be/E8fmpOIcPVA?si=3YDSIVAQLR8GjT5l)

### AMT - a package for the analysis of animal telemetry data

TODO: why scientists use AMT: paragraph on popular applications for this package

#### Bringing your data into `amt`

~~~

# lets start by loading in a few packages we will use and installing the amt package itself
library(tidyverse)
library(ggplot2)
library(devtools)
#devtools::install_github("jmsigner/amt")
#install.packages("amt")
library(amt)
??amt
~~~
{: .language-r}

#### Create an example dataset

~~~
# lets start by creating a basic dataframe and going over some important functions 
# create data frame
df1 <- tibble(x = 1:3, y = 1:3)
is.data.frame(df1)
df1
~~~
{: .language-r}

#### Creating a 'track'

~~~

# make_track() takes data frame and the necessary information we need and combines everything together
# At the moment amt supports two types of tracks: track_xy is a track that only has coordinates, and track_xyt is a track that has a timestamp associated to each coordinate pair.
# the variables necessary for make_track are x and y (coordinates), t (timestamp if you are using it), and id
# make_track(x, y, t, id=)
??make_track

# so we can do this with just coordintates 
tr1 <- make_track(df1, x, y)
is.data.frame(tr1)
class(tr1)

# or we can do this with coordinates + timestamps
df1 <- tibble(x = 1:3, y = 1:3, t = lubridate::ymd("2017-01-01") + lubridate::days(0:2))
tr2 <- make_track(df1, x, y, t)
class(tr2)

# and we can also include id information too, which allows us to later break up analysis by individuals  
df1 <- tibble(x = 1:3, y = 1:3, t = lubridate::ymd("2017-01-01") + lubridate::days(0:2), 
              id = 1, age = 4)

# our df1 data now has x and y (coordinates), 
# first we only create a track_xy
tr3 <- make_track(df1, x, y, id = id, age = age)

# now lets create a track_xyt with timestamps as well
tr4 <- make_track(df1, x, y, t, id = id, age = age)

~~~
{: .language-r}

### Example: using real data

~~~
# Try with a real data example ####
data(sh)
head(sh)

# Before creating a track, we have to do some data cleaning:
# check if any coordinates are missing (and if so, remove the relocation)
# parse the date and time
# create a time stamp
# check for duplicated time stamps
# create two new columns for the id and month of the year
# this type of data processing is usually what is done first with acoustic telemetry data anyways, but its good to make sure all of those things are covered before we keep going here

# check if all observations are complete
all(complete.cases(sh)) # no action required

# parse date and time and create time stamps
sh$ts <- as.POSIXct(lubridate::ymd(sh$day) +
                      lubridate::hms(sh$time))

# check for duplicated time stamps
any(duplicated(sh$ts))

# We have some duplicated time stamps, these need to be removed prior to
# creating a track.
sh <- sh[!duplicated(sh$ts), ]

# create new columns
sh$id <- "Animal 1"
sh$month <- lubridate::month(sh$ts)

# now we can make a track
tr1 <- make_track(sh, x_epsg31467, y_epsg31467, ts, id = id, month = month)

# the column names of the data set already indicate the CRS of the data 
# we can add this information when creating a track
tr1 <- make_track(sh, x_epsg31467, y_epsg31467, ts, id = id, month = month, 
                  crs = 31467)

# amt was heavily inspired through workflows suggested by the popular packages from the tidyverse - so it is compatibile with many tidyverse functions

# the above steps could easily be connected using pipes 
# note that result will be exactly the same BUT when you have big datasets this may be more efficient to do in steps
data(sh)

tr2 <- sh %>% 
  filter(complete.cases(sh)) %>% 
  mutate(
    ts = as.POSIXct(lubridate::ymd(day) + lubridate::hms(time)), 
    id = "Animal 1", 
    month = lubridate::month(ts)
  ) %>%  
  filter(!duplicated(ts)) %>%  
  make_track(x_epsg31467, y_epsg31467, ts, id = id, month = month, 
             crs = 31467)

# once you've used make_track() to create a track_xy, it behaves like a regular data.frame
# we can use all data manipulation verbs for base R or tidyverse
tr3 <- tr2 %>% 
  filter(month == 5)

# we are left with a track
class(tr3)
~~~
{: .language-r}


##### Transforming CRS

If we set the CRS when creating a track (we can verify this with has_crs), we can transform the CRS of the coordinates with the function transform_coords (a wrapper around sf::st_transform()). For illustration, we will transform the CRS of tr2 to geographical coordinates (EPSG:4326)

~~~

transform_coords(tr2, 4326)

~~~
{: .language-r}


Several functions for calculating derived quantities are available. We will start with looking at step length. The function step_lengths can be used for this.


~~~
tr2 <- tr2 %>% 
  mutate(sl_ = step_lengths(tr2))

#summarize 
summary(tr2$sl_)

~~~
{: .language-r}

Notes:
1.  there is a NA for the last step length, this is expected because we are still in a point representation (i.e., there is no step length for the last relocation) 
2.  the range is fairly large ranging from 0 to almost 5 km. Before looking at step lengths in any further detail, we will have to make sure the sampling rate is more or less regular (i.e., the same time step between any two points).


The function summarize_sampling_rate provides an easy way to look at the sampling rate. This suggests that a sampling rate for 6 hours might be adequate. We can then use the function track_resample to resample the track and only keep relocations that are approximately 6 hours apart (within some tolerance, that can be specified). We will use the function lubridate::hours to specify the sampling rate and lubridate::minutes to specify the tolerance. Both arguments rate and tolerance are expected to be a Period.



~~~
summarize_sampling_rate(tr2)

tr3 <- tr2 %>% 
  track_resample(rate = hours(6), tolerance = minutes(20))
~~~
{: .language-r}


#### Example: dealing with several animals

Up to now we have only considered situations with one animal. However, in most telemetry studies more than one animal are tracked and we often want to calculated movement relevant characteristics for several animals individually.

`amt` does not provide a infrastructure for dealing with several animal, however, list-columns from the tidyverse can be used to manage many animals.

Because a track is just a tibble all tidyverse verbs can be used

The general strategy consists of three steps:
1.  Nest a track by one or more columns. This retains the unique values of the grouping variable(s) and creates a new list-column with tracks.
2.  Now we can perform operations on the grouped data creating a new list column. This can be done in a combination with mutate and map (instead of map also lapply could be used).
3.  Select the relevant columns and unnest. With `select()` we can select columns of interest and reverse the nesting with the function `unnest()`.

~~~

# lets try this with fisher data
data("amt_fisher")

# we start by loading the data and creating a track of all individuals together
trk <- amt_fisher %>% 
  make_track(x_, y_, t_, id = id)


# next, we group the track by id and nest the track.
trk1 <- trk %>% 
  nest(data = -"id")

# get the data for the first animal
y <- trk1$data[[1]]

# apply the data analysis
y %>% 
  track_resample(rate = minutes(30), tolerance = minutes(5)) %>% 
  steps_by_burst()

# we now want to apply exactly the same logic to all animals
# we can do this by using a map and save the results to a new column using mutate
trk2 <- trk1 %>% 
  mutate(steps = map(data, function(x) 
    x %>% 
      track_resample(rate = minutes(30), tolerance = minutes(5)) %>% 
      steps_by_burst()))

# finally, we can select id and steps, unnest the new data_frame and create a plot of the step-length distributions.
trk2 %>% 
  dplyr::select(id, steps) %>% 
  unnest(cols = steps) %>% 
  ggplot(aes(sl_, fill = factor(id))) + geom_density(alpha = 0.4)





~~~
{: .language-r}



### Calculate home-range overlaps
~~~
# Calculating home-range overlaps with amt ####
amt_fisher <- amt_fisher

# we will use tracking data from Fishers from New York State, USA.
leroy <- amt_fisher %>% 
  filter(name == "Leroy")
lupe <- amt_fisher %>% 
  filter(name == "Lupe")

# create a template raster for the kernel density estimates (KDE)
# make_trast() takes the track made with make_track() and creates a template raster 
# it requires a track as the x argument make_trast(x...)
# so our process should usually be track -> trast -> kde
# here, amt_fisher is set up with the correct arguments to make it a track, so we can proceed by just giving make_trast amt_fisher
trast <- make_trast(amt_fisher %>% 
                      filter(name %in% c("Leroy", "Lupe")), res = 50)

# now we can estimate home-ranges for both fishers
# hr_kde requires a trast, and we can assign the level of KDE we'd like to look at
# here we will take a look at 50% and 90% home range
hr_leroy <- hr_kde(leroy, trast = trast, levels = c(0.5, 0.9))
hr_lupe <- hr_kde(lupe, trast = trast, levels = c(0.5, 0.9))


# next we can use hr_overlap() to take these values and calculate the amount of overlap between both home ranges
# hr and phr are directional, this means the order matters
# for all other overlap measures the order does not matter
# the output here gives us a value of % overlap at the levels we assigned in hr_kde
hr_overlap(hr_leroy, hr_lupe, type = "hr") 
hr_overlap(hr_lupe, hr_leroy, type = "hr")


# lets calculate daily ranges for Lupe and then and then see how different ranges overlap with each other.
trast <- make_trast(lupe, res = 50)

# then we add a new column with day and calculate for each day a KDE home range.
dat <- lupe %>%  
  mutate(week = lubridate::floor_date(t_, "week")) %>%  
  nest(data = -week) %>% 
  mutate(kde = map(data, hr_kde, trast = trast, levels = c(0.5, 0.95, 0.99)))

# now we can use the list column with the home-range estimates to calculate overlap between the different home-ranges
# by default which = "consecutive", this means for each list entry (= home-range estimate) the overlap to the next entry will be calculated.
hr_overlap(dat$kde, type = "vi")

# this works as well, if we set conditional = TRUE
hr_overlap(dat$kde, type = "vi", conditional = TRUE)

# sometimes it can be useful to provide meaningful labels. We can do this with the labels argument.
hr_overlap(dat$kde, type = "vi", labels = dat$week)


# Overlap between a home range and a simple feature #### 
# the function hr_overlap_feature allows to calculate percentage overlap (HRindex) between a home
# to illustrate this feature, we will use again the data from lupe and calculate the intersection with an arbitrary polygon
poly <- amt::bbox(lupe, buffer = -500, sf = TRUE)
poly1 <- amt::bbox(lupe, sf = TRUE)
hr <- hr_mcp(lupe)
ggplot() + 
  geom_sf(data = hr_isopleths(hr)) + 
  geom_sf(data = poly, fill = NA, col = "red") +
  geom_sf(data = poly1, fill = NA, col = "blue")

# now we can calculate the overlap again with the feature 
hr_overlap_feature(hr, poly, direction = "hr_with_feature")
hr_overlap_feature(hr, poly1, direction = "feature_with_hr")

# the same work with several home-range levels:
hr <- hr_mcp(lupe, levels = c(0.5, 0.9, 0.95))
hr_overlap_feature(hr, poly, direction = "hr_with_feature")



~~~
{: .language-r}


### Calculate and plot KDE per ID

~~~
# Calculate KDE per ID ####
# we can also calculate home ranges per ID using our tidyverse packages to break things down, it just takes a few extra steps
# this is helpful to know for when you have many different IDs and want to look at ranges the individual level
# lets use the amt_fisher data again as an example 
# set data
dat <- amt_fisher 

# make track for real this time putting all the necessary variables into make_track()
dat_track <- make_track(dat, x_, y_, t_, id=id, all_cols = TRUE)

# now lets make our trast but this time while we split ids for individuals 

# here we can use split to make a trast for each id, and create the pieces we need to calculate KDE for each individual
library(furrr)

# split and create trast by id
trast_1 <- dat_track %>% 
  split(.$id) %>% 
  map(~make_trast(.x))

# split and create hr_kde_ref by id
hr_kde_ref_1 <- dat_track %>% 
  split(.$id) %>% 
  map(~hr_kde_ref(.x)) 

# split dat_id_kde_href by id
dat_id_kde_href <- dat_track %>%
  split(.$id)

# and now put the above three steps together to produce our final KDE output for each ID



# next we take all three parts and put them together for a final output
kde_fisher <- future_pmap(list(dat_id_kde_href, trast_1, hr_kde_ref_1), 
                        function(first, second, third)
                          hr_kde(x = first, 
                                 trast = second,
                                 h = third, 
                                 levels = c(0.5, 0.95)), .progress = TRUE)


# we can then take the results of kde_fisher, apply hr_isopleths to each element, and add the fisher ids so that we can graph everything
kde_isopath <- kde_fisher %>% 
  future_map(~ hr_isopleths(.x)) %>% 
  bind_rows(.id = "fisher_id")


# now we can plot everything together
library(ggplot2)
kde_isopath$level <- as.factor(kde_isopath$level)

# and plot
ggplot() + 
  geom_sf(data = kde_isopath, aes(fill = level, col = fisher_id)) +
  theme_bw()

# or separate (better visually)
ggplot() + 
  geom_sf(data = kde_isopath, aes(fill = level), size = 4) + 
  facet_wrap(~ fisher_id) +
  theme_bw()




~~~
{: .language-r}



### Example: putting it all together
~~~

# Now lets try everything with some real telemetry data ####

# here I am going to put everything together to take a look at some acoustic telemetry data and demonstrate again how to calculate some home ranges at a few different levels
# my focus here is on looking at amt to create KDEs, plots to go along with those values, and also looking at home range overlaps with features

# load in data 
df <- hfx_qualified_detections_2022_workshop
head(df)

# first we'll start off by converting out lat and lon coordinates to utm 
library(sf)
library(tidyverse)
library(amt)

# convert to an sf object with WGS 84 CRS (EPSG:4326)
df_sf <- st_as_sf(df, coords = c("longitude", "latitude"), crs = 4326)

# transform to UTM Zone 20N (EPSG:32620)
df_sf_utm <- st_transform(df_sf, crs = 32620)

# extract the UTM coordinates
df$utm_x <- st_coordinates(df_sf_utm)[, 1]
df$utm_y <- st_coordinates(df_sf_utm)[, 2]

# ok we see the new columns have been added
head(df)

# and there are no NAs, perfect 
any(is.na(df$utm_x))
any(is.na(df$utm_y))

# next thing I'll do is check and see how many individual IDs there are in the data 
# and I'll quickly rename "fieldnumber" to "FishID" just to keep it simple
df <- df %>%
  rename(FishID = fieldnumber)
length(unique(df$FishID)) # 208! That's a lot of individuals

# here we will start setting up our data for the actual analysis 
# first I want to look and see how many detections there are per fish
df_det_sum <- df %>%
  group_by(FishID) %>%
  summarize(
    num_dets = n(),
    unique_receivers = n_distinct(station)
  )


# so there are a bunch of fish that have 1 detection
# I'll go ahead and filter every fish that has less than 10 detections just to make sure we have enough for analysis
# not sure what the magic number is here, but 10 feels good to start
# and while I'm filtering, I'm also going to pull out the columns we need for further analysis with amt, and remove excess data, rejoining the filtered dets with inner_join 
df_2 <- df %>%
  group_by(FishID) %>%
  summarize(
    num_dets = n(),
    unique_receivers = n_distinct(station)
  ) %>%
  filter(num_dets >= 10, unique_receivers >= 5) %>%
  inner_join(
    df %>%
      dplyr::select(utm_x, utm_y, FishID, datecollected, monthcollected),
    by = "FishID"
  )

# great! Now we can go ahead and use our amt functions 

# we will look at the data as a whole first (no ids)
# first our track - and here I'm also including adding a crs arguement because we know where this data was collected and it will help with spatial analysis 
df_track <- make_track(df_2, utm_x, utm_y, datecollected, crs = 32620, all_cols = TRUE)

# then our trast
df_trast <- make_trast(df_track)

# and now our kde - and we will try three levels here
df_kde_ref <- hr_kde(df_track, trast=df_trast, h = hr_kde_ref(df_track), levels = c(0.5, 0.90, 0.95))
df_kde_ref

# and we can quickly plot it with base r
plot(df_kde_ref, col = c("red", "blue", "yellow"))

# but I prefer to use ggplot
# turn into contours
df_contours <- hr_isopleths(df_kde_ref)

ggplot() +
  geom_sf(data = df_contours, aes(fill = factor(level)), color = NA) +
  scale_fill_brewer(name = "Confidence\nLevel")


# now we can overlay an arbitrary box, then practice using the overlap metrics 
# this is useful if you ever want to know how your data overlaps with a boundary 
# we will do this by defining boundaries then creating a polygon

# lets create a little dataframe with coordinates
library(sf)
lat <- c(44.25, 44.25, 43.6, 43.6, 44.25) 
lon <- c(-63.55, -63.1, -63.1, -63.55, -63.55)

# combine the coordinates into a matrix
coords <- cbind(lon, lat)

# create a polygon from the coordinates
polygon <- st_polygon(list(coords))

# create an sf object with the polygon
sf_polygon <- st_sf(name = "test_boundary", geometry = st_sfc(polygon), crs = 4326)

# create a UTM projection string
utm_crs <- paste0("+proj=utm +zone=", 20, " +datum=WGS84 +units=m +no_defs")

# transform the coordinates to UTM
sf_polygon_utm <- st_transform(sf_polygon, crs = utm_crs)

# and finally, we can overlay this on our density contour ggplot
ggplot() +
  geom_sf(data = df_contours, aes(fill = factor(level)), color = NA) +
  scale_fill_brewer(name = "Confidence\nLevel") +
  geom_sf(data = sf_polygon_utm, fill = NA, colour = "green", lwd = 1)

# AND take a quick look at how much overlap we get between the data and the feature
hr_overlap_feature(df_kde_ref, sf_polygon_utm, direction = "hr_with_feature", feature_names = "boundary_box")



# now lets try and break up our data by id
# make a new track but this time we'll include FishID
dat_track_id <- make_track(df_2, utm_x, utm_y, datecollected, id = FishID, crs = 32620, all_cols = TRUE)

# the below steps can in theory be done together, but I've found it more efficient to break things up 
# with data that is vast spatially, you may also need to come up with a day to define the extent of your data which is not necessary here, may look something like this:
# trast_1 <- make_trast(dat_track_id, res = max(c(extent_max(dat_track_id)/100, 1e-09)))

# split and create trast by id
trast_2 <- dat_track_id %>% 
  split(.$FishID) %>% 
  map(~make_trast(.x))

# split and create hr_kde_ref by id
hr_kde_ref_2 <- dat_track_id %>% 
  split(.$FishID) %>% 
  map(~hr_kde_ref(.x, rescale = "none")) 

# split dat_id_kde_href by id
dat_id_kde_href <- dat_track_id %>%
  split(.$FishID)

# and now put the above three steps together to produce our final KDE output for each ID
library(furrr)
kde_fishID <- future_pmap(list(dat_id_kde_href, trast_2, hr_kde_ref_2), 
                          function(first, second, third)
                            hr_kde(x = first, 
                                   trast = second,
                                   h = third, 
                                   levels = c(0.5, 0.90, 0.95)), .progress = TRUE)


# create isopath data to plot
kde_isopath_id <- kde_fishID %>% 
  future_map(~ hr_isopleths(.x)) %>% 
  bind_rows(.id = "FishID") #. name your id whatever you

# set levels as factors 
kde_isopath_id$level <- as.factor(kde_isopath_id$level)

# plot it all by animal id
ggplot() + 
  geom_sf(data = kde_isopath_id, aes(fill = level)) + 
  facet_wrap(~ FishID) +
  scale_fill_brewer() +
  theme_bw()

# and if you're working with a boundary, you can do the same thing above with the same boundary we set above
ggplot() + 
  geom_sf(data = kde_isopath_id, aes(fill = level)) + 
  facet_wrap(~ FishID) +
  geom_sf(data = sf_polygon_utm, fill = NA, colour = "green", lwd = 1) +
  scale_fill_brewer() +
  theme_bw()

# with the option to input id= in our track, you can basically give make_track() anything as an id and it will split your data accordingly
# for example, you can sub FishID for month, or create new variable in your data to assign FishID and month or FishID and day if you want to break it down further 

# so the last thing we'll so here is just do the same thing but split by month instead of FishID
# I'm going to remove April (month 4) here before moving any further just because there is not enough data to compute down the way 
df_3 <- df_2 %>%
  filter(monthcollected != 4)

# then proceed as above but with month
dat_track_month <- make_track(df_3, utm_x, utm_y, datecollected, id = monthcollected, crs = 32620, all_cols = TRUE)

trast_2_month <- dat_track_month  %>% 
  split(.$monthcollected) %>% 
  map(~make_trast(.x))

hr_kde_ref_2_month <- dat_track_month  %>% 
  split(.$monthcollected) %>% 
  map(~hr_kde_ref(.x, rescale = "none")) 

dat_id_kde_href_month <- dat_track_month  %>%
  split(.$monthcollected)

kde_month <- future_pmap(list(dat_id_kde_href_month, trast_2_month, hr_kde_ref_2_month), 
                          function(first, second, third)
                            hr_kde(x = first, 
                                   trast = second,
                                   h = third, 
                                   levels = c(0.5, 0.90, 0.95)), .progress = TRUE)


kde_isopath_month <- kde_month %>% 
  future_map(~ hr_isopleths(.x)) %>% 
  bind_rows(.id = "month") #. you can name your id whatever you'd like here so I'm renaming monthcollected as just month to shorten it BUT I'd recommend against this move so you don't get your variables confused!

kde_isopath_month$level <- as.factor(kde_isopath_month$level)

# reorder month as needed
month_order <- factor(kde_isopath_month$month, levels = c("1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12"))
kde_isopath_month <- kde_isopath_month %>%
  mutate(month = month_order)

# and finally plot and wrap by month - no data for April and Dec! 
ggplot(kde_isopath_month, aes(fill = level)) + 
  geom_sf() + 
  facet_wrap(~ month) +
  scale_fill_brewer() +
  theme_bw()
~~~
{: .language-r}
