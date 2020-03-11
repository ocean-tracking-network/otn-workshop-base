---
title: Accounting For ACF
teaching: 30
exercises: 0
---

Coming soon!


~~~
####################################
### lesson 2: accounting for acf ###
####################################

# to try to better account for acf we will use markmodmover
# markmodmover models the mean of the step length as a function of the previous
# step length, thus accounting for the acf
# do note that some of this acf can be caused by the linear interpolation of the data
# markmodmover uses S4 classes, which are a bit more formal than the S3 classes that
# are very frequently used, and that are used by moveHMM. This is just a different way
# of calling functions in R. Here's a link to a really good explanation of the different
# object oriented classes available in R
# http://adv-r.had.co.nz/OO-essentials.html
# so we can check out the vignette for markmodmover:
vignette("markmodmover")
# this gives us a nice schematic of the package workflow. just like in movehmm,
# you start with your data, you put it in the correct format using a package function,
# then you fit the model. you can also tweak some of the model fitting options
# using setmodel4m, and you can simulate from your fitted model (to assess accuracy)


# let's start by putting our data in the correct format. This package was designed
# for irregularly spaced (in time) data, so we can just feed data4M the original data frame
# and then use a package interpolation function
# however, this package only takes data in lats and lons. our data are projected,
# so we need to "unproject" them!
# awesome overview to projections here: https://www.nceas.ucsb.edu/~frazier/RSpatialGuides/OverviewCoordinateReferenceSystems.pdf
# i'm using rgdal, lots of people are using sf now which is supposed to be a bit more readable
# below is example code of reading in a shapefile, but i've added it to the rda file anyways
# world <- readOGR(dsn="~/Documents/Shapefiles", layer="World") #natural earth
yaps1315 %>%
  select(x, y) %>%
  as.matrix() %>%
  SpatialPoints(proj4string=CRS("+init=epsg:32632")) -> pike_proj
pike_proj %>% spTransform(CRS("+proj=longlat")) -> pike_unproj
plot(world, xlim=c(0, 11), ylim=c(50, 60), col="cadetblue")
points(pike_unproj, type='l', lwd=5, col="tomato") #there we are in Denmark!
# (i typically plot it to make sure it worked)

# so now we use the data4M() function to prep the data
# it has a bit of flexibility in the naming of the data, i use the shortest possible (laziness)
# so i renamed to lon and lat
pike_unproj@coords %>%
  as.data.frame() %>%
  mutate(date = yaps1315$top) %>%
  dplyr::select(date, x, y) %>%
  rename(lon=x, lat=y) %>%
  data4M() -> pike
pike     
# so there are three sections, one describing the observed locations,
# one describing the time differences, and one describing the interpolated locations
# the interpolated locations are empty, we need to pick a time step!
# the time differences are calculated in hours
90/3600 # the mean so let's stick with 90s for our time step
# markmodmover has its own interpolation function
pike <- interpolate(pike, Time.Step=90/3600) # takes the time step in hours
pike
# now under interpolated locations we have some summary info
# in markmodmover, missing data (gaps in time) are dealt with by splitting the track
# into groups and then fitting the same HMM to each group (setting parameter estimates
# to be equal across tracks). A group cutoff (the interval used to determine when to
# split the track up) is automatically chosen, see Lawler et al. (2019) for details.
# you can adjust this using the Group.Cutoff argument
# here we have only 1 group, so we didn't need to split the track up at all.

# let's plot the new data
str(pike) # gives a sense of the structure of s4
# have to use the @ symbol to access slots
# or some of these have functions to access the slots
# we could have used observedLocations(pike) instead
plot(Lat~Lon, data=pike@Observed.Locations, type="l")
points(Lat~Lon, data=pike@Interpolated.Locations, pch=20, col='royalblue')
# everything is lying on the path again
# you can also use plot()
plot(pike)
# The last two plots are interesting, but hard to see right now because there are a few
# outlying step lengths
# we can clone the data and take them out to take a closer look
# (note that will change the plot a bit though)
# this gives us a list of the outliers, we'll take out step lengths >2 based on this and the axes
pike@Movement.Data$Movement.Data$Step.Length %>% boxplot.stats()
pike4viz <- pike
pike4viz@Movement.Data$Movement.Data <- pike4viz@Movement.Data$Movement.Data %>% filter(Step.Length < 2)
plot(pike4viz, y="data")
# These are both 2 dimensional kernal density estimators (using MASS::kde2d)
# the first one is basically a kde of each of the step vectors centered at 0
# the second is a kde of the step length at time t vs at time t-1, which
# can be used to help figure out what kind of model to fit - if it looks
# like a continuous line along y=x, then use the carHMM. if it looks like
# a series of droplets along y=x, then use a regular HMM. See Lawler et al. 2019.
# looks to me like suggesting we should use carHMM, which corroborates previous evidence

# now that the data are in the correct format, we can fit the model!
# with this model, starting values are picked randomly
# it also uses a wrapped cauchy for a turning angle distribution
# but you can pick between a gamma and log normal for the step lengths (gamma is default)
# here i stick with default
mod_ac <- fit(pike)
mod_ac
# note a couple of things
# wrapped cauchy distribution here is parameterized with a scale parameter between 0 and 1
# higher value -> more concentrated
# mean of the gamma distribution is mean = (1-ac)*reversion.level + ac*previous.step.length
# so it changes with every step, it's not just dependent on the state anymore

# state definitions have switched, compare with previous mod again
mod
# in previous models, the longer step lengths were associated with state 1, now associated with state 2
# tpms are pretty similar tho!
states_ac <- viterbiPath(mod_ac)
data.frame(val = rle(states_ac)$values, n = rle(states_ac)$lengths) %>%
  ggplot(aes(val %>% factor, n)) + geom_violin()
# looks pretty similar, but note some noticeably longer step lengths in the residency state

# now we take a look at the model diagnostics using plot90 again
plot(mod_ac)

# we can also compare the pseudoresiduals from the two models
# note both models used interpolated locations on a 90s scale
par(mfrow=c(2,1))
pseudoRes(mod)$stepRes %>% acf(main="moveHMM", na.action=na.pass)
mod_ac@Residuals$Step.Length %>% acf(main="markmodmover")
# acf is pretty reduced, but you can still see some

# we also have AIC with markmodmover
mod_ac$AIC
~~~
{:.language-r}
