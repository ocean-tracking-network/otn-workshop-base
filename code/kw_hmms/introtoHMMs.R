############## to do 
### lesson 1: fit an HMM; picking time step; picking starting values, interpretation, assessing model fit
### lesson 2: accounting for acf
### lesson 3: picking between numbers of states
### lesson 4: fitting to multiple animals
### lesson 5: fitting to seemingly messier data is hard

# i always start by removing all objects and setting my working directory
# set your path here
rm(list=ls())
setwd("~/Desktop/kw_hmms")

# install the packages
install.packages("TMB")
install.packages("moveHMM")
devtools::install_github("lawlerem/markmodmover", build_vignettes=TRUE)
install.packages('circular')
install.packages('rgdal')
install.packages('gridExtra')

# now we can load the packages
library(moveHMM)
library(markmodmover)
library(dplyr)
library(ggplot2)
library(gridExtra)
library(rgdal)

############################
### lesson 1: fit an HMM ###
# picking time step
# picking starting values
# interpretation
# assessing model fit
############################

# let's bring in the data for the first HMMs
load("pikedat.rda")
ls()
# so we have data from the hydrophones, data for the lake, and data for the two models fit to different fish
# these are yaps output, so we need to keep in mind that we're going to be fitting more models to model output

# here's an initial view of the data (thanks Henrik for the code!)
plot(Y~X, data=lake, col="black", asp=1, type="l") # lake
points(y~x, data=hydros, pch=20, cex=2, col="navy") # receivers
lines(y~x, data=yaps1315, col="cadetblue")
lines(y~x, data=yaps1335, col="tomato")


# overview of the data
# Let's take a look at all of the variables
head(yaps1315)
# Here x is the Easting, and y is the Northing, that means we're projected
# it's in UTM32N - epsg32632 (projection)
# sd_x and sd_y are the standard deviations associated with the YAPS model
# top is the time of the ping
# nobs is the number of receivers that detected each ping
# velocity is the instantaneous speed of sound

# let's first start just by plotting the data
# since we're looking at predicted values from a model, I would also like to look at a 
# confidence interval around the predictions (normally distributed - let's just use 95% CI)
plot(yaps1335$x, yaps1335$y, type="l")
points(yaps1335$x-1.96*yaps1335$sd_x, yaps1335$y-1.96*yaps1335$sd_y, 
       type='l', col='skyblue')
points(yaps1335$x+1.96*yaps1335$sd_x, yaps1335$y+1.96*yaps1335$sd_y, 
       type='l', col='skyblue')


plot(yaps1315$x, yaps1315$y, type="l")
points(yaps1315$x-1.96*yaps1315$sd_x, yaps1315$y-1.96*yaps1315$sd_y, 
       type='l', col='skyblue')
points(yaps1315$x+1.96*yaps1315$sd_x, yaps1315$y+1.96*yaps1315$sd_y, 
       type='l', col='skyblue')
# neither of these confidence intervals look very wide, which is a good sign

# i also like to take a look at each location axis against time, which tells me a bit 
# about whether they are continuously spaced, whether there are any gaps, and a bit about the behaviours
plot(x ~top, data=yaps1335, type="p")
plot(y ~top, data=yaps1335, type="p")
# these first two plots, we see no gaps, and nothing really looks out of the ordinary 
# although there is almost a cyclical change, and the spread gets wider as time goes on
plot(x ~top, data=yaps1315, type="p")
plot(y ~top, data=yaps1315, type="p")
# these next two spots show some interesting behaviour: it looks like the animal might be 
# showing some clear residency behaviour where it's not changing it's position at all 
# and then shows some clear directed movement 
# pike are burst swimmers, so we know of at least three behaviours, a sit-and-wait, a burst, 
# and a likely movement between the sit-and-wait spots, but we might not be able to 
# pick up the burst behaviour because it's really quick 


# the first thing that we need to do is interpolate the data onto a regular time interval
# in order to do this, we need to pick a time step
# there are a couple of different schools of thought about this
# one is to pick a time step that will give you a number of interpolated locations close to the 
# number of observations that you have
# let's try that first, so we need to take a look at the distribution of the temporal intervals

# when working with time, note that just the regular diff function will pick the units for you
# if you want to specify the units then you need to use difftime and supply two vectors
diff(yaps1315$top) %>% as.numeric() %>% density() %>% plot()
# check out a density plot of the values
difftime(yaps1315$top[-1], yaps1315$top[-nrow(yaps1315)], units="secs") %>% as.numeric() %>% density() %>% plot()
# uniformly distributed from 60 to 120, makes sense (random burst interval tag)
difftime(yaps1315$top[-1], yaps1315$top[-nrow(yaps1315)], units="secs") %>% mean()
# a value of 90s would probably be good to start!

# now let's interpolate the data
tempinterp <- function(anim, ts){
  # ts is time step in seconds
  # anim is animal with datetime in posix, then longitude, then latitude
  # colnames are "date", "x", and "y"
  
  t0 = anim$date[1] # first time step
  tT = anim$date[nrow(anim)] # last time step
  t = seq(t0, tT, by=ts) # sequence of time steps
  
  # interpolate between the two
  loc <- data.frame(date=t, 
                    x = approx(anim$date, anim$x, xout = t)$y,
                    y = approx(anim$date, anim$y, xout = t)$y)
}

# interpolate the first pike's data
yaps1315 %>% rename(date=top) %>% tempinterp(ts=90) -> pike
head(pike)
# note that the times are all 90 seconds apart
# check that all the points lie on the path
yaps1315 %>% ggplot(aes(x=x, y=y)) + geom_path() + geom_point(aes(x, y), data=pike, col='cadetblue')



# now that we have locations occuring in regular time, the next step is to decompose the track 
# into step lengths and turning angles. There are a few ways to do this, and different packages
# do it in different ways. It's really important to understand your projection (or lack thereof)
# with moveHMM, we need to use the prepData function. 
pike_prep <- prepData(pike, type="UTM")
# type can be either UTM or LL - use UTM for easting/northing (because we are projected)
# use coordNames argument if your locations are named other than the default (x, y)
head(pike_prep)
tail(pike_prep)
# here we see a couple of things - 
# there is an animal ID that is automatically created - we'll get back to this later
# step is the step length - these are in m because our original locations are in m
# angle is the turning angle - these are in radians (multiply by 180/pi if you want degrees)
# note a couple of NAs, because it takes two locations to calculate a step length and 
# three to calculate a turning angle. Also note the alignment of these NAs suggests that
# the step length from times t-1 to t and the angle between times t-1, t, and t+1 will 
# be informing the same state

# now let's take a look at the distributions
# moveHMM has a generic plotting function for the processed data
plot(pike_prep)
# i also like to look at the densities and histograms side by side
par(mfrow=c(2,2))
density(pike_prep$step, na.rm=TRUE) %>% plot(main="Step Length Density")
hist(pike_prep$step, main = "Step Length Histogram")
density(pike_prep$angle, na.rm=TRUE) %>% plot(main="Turning Angle Density")
hist(pike_prep$angle, main = "Turning Angle Histogram")
# our objective is to look for multiple states 
# in modelling terms, this means that we are assuming that these observations shouldn't be 
# modelled with just one underlying probability distribution, but multiple
# i.e., these empirical densities actually contain multiple parametric densities within them. 

# in an HMM, we want to estimate these multiple densities, and the states that relate to them. 
# an optimization routine is an algorithm that seeks to find the optimum from a function
# moveHMM uses nlm, markmodmover uses nlminb
# in order to optimize a function, you need to have starting values
# if your function is bumpy, then it can be harder to find a global optimum, so you want 
# to be careful about your choice of starting values, and it's a good idea 
# to check multiple sets
# to pick starting values, I like to overlay densities on my histograms
# for moveHMM, the default densities are gamma (step length) and von mises (turning angle)

?dgamma # shape and rate parameter 
# rate is inverse of scale, so as rate goes up, the spread goes down
# shape is eponymous it literally determines the shape of the distribution
# get a sense of the distribution with the following plots
par(mfrow=c(1,1))
curve(dgamma(x,1,10), col="black", lwd=2)
curve(dgamma(x,2,10), add=TRUE, col="royalblue", lwd=2)
curve(dgamma(x,5,10), add=TRUE, col="cadetblue", lwd=2)
curve(dgamma(x,10,10), add=TRUE, col="mediumseagreen", lwd=2)
curve(dgamma(x,2,10), col="black", lwd=2)
curve(dgamma(x,2,5), add=TRUE, col="royalblue", lwd=2)
curve(dgamma(x,2,2), add=TRUE, col="cadetblue", lwd=2)
curve(dgamma(x,2,1), add=TRUE, col="mediumseagreen", lwd=2)

?circular::dvonmises #mean mu and concentration kappa
# mu determines where the angles are centered
# concentration determines how concentrated the distribution is around the mean
# let's play
curve(circular::dvonmises(x,0,1), from=-pi, to=pi, ylim=c(0,1), col="black", lwd=2)
curve(circular::dvonmises(x,0,5), add=TRUE, col="royalblue", lwd=2)
curve(circular::dvonmises(x,pi,1), add=TRUE, col="cadetblue", lwd=2)
curve(circular::dvonmises(x,pi,5), add=TRUE, col="mediumseagreen", lwd=2)
# pretty clear that the mean determines the location, and the concentration 
# determines the spread


# now we need to pick a set of starting values
# there is a great guide from Théo Michelot and Roland Langrock: 
# https://cran.r-project.org/web/packages/moveHMM/vignettes/moveHMM-starting-values.pdf
# i like to overlay a few different sets on histograms of my data
# for the step lengths, we're normally looking for a distribution that is more
# concentrated around the smaller step lengths, and another that is more 
# spread which encapsulates the longer (but less dense) step lengths
hist(pike_prep$step, breaks=20, freq=FALSE, main = "pike step lengths")
curve(dgamma(x,0.8,rate=1), n=200, add=TRUE, col="royalblue", lwd=4)
curve(dgamma(x,1.5,rate=0.5), n=200, add=TRUE, col="cadetblue", lwd=4)
curve(dgamma(x,1.2,rate=0.01), n=200, add=TRUE, col="navyblue", lwd=4) 
# maybe a third state to capture the outliers? 

# for the turning angles
# here we have a distribution that is fairly clear in terms of the 
# two states - typically, we like to look for a state with a lot of observations
# around 0, which is indicative of directed movement, and then another flatter 
# distribution to encapsulate all of the other directions, which suggests more 
# random or undirected movement. Sometimes, as in this case, we might actually
# see a bump at the edges (around pi and -pi) suggesting that there is a state
# with course reversals
hist(pike_prep$angle, freq=FALSE, main = "pike turning angles")
curve(circular::dvonmises(x,pi,0.3), n=200, add=TRUE, col="royalblue", lwd=4)
curve(circular::dvonmises(x,0,2.5), n=200, add=TRUE, col="cadetblue", lwd=4)


# now that we have chosen some starting values, we can fit our first HMM!
# note that moveHMM parameterizes the gamma in terms of the mean and standard
# deviation, so we need to change our parameters over
# mean = shape/rate
# sd = shape^(1/2)/rate
# can find these formulas on wikipedia page
sl_init_mean <- c(1.5/0.5, 0.8/1)
sl_init_sd <- c(sqrt(1.5)/0.5, sqrt(0.8)/1)
ta_init_mean <- c(0, pi)
ta_init_con <- c(2.5, 0.3)
# note that the order matters! The first parameters for each observation 
# apply to the first state, and so on...
mod <- fitHMM(data = pike_prep, 
              nbStates = 2, 
              stepPar0 = c(sl_init_mean, sl_init_sd),
              anglePar0 = c(ta_init_mean, ta_init_con),
              formula = ~1, 
              stepDist = "gamma", 
              angleDist = "vm")
# and it fitted! let's check out the results

# model summary
mod
# state 1: directed movement with long step lengths
# state 2: undirected movement with shorter step lengths
# transition probability coefficients are in terms of the probabilities of switching to 
# a different state
# intial distribution is of the behavioural states

# model plots
plot(mod)

# model confidence intervals
CI(mod)

# model states
states <- viterbi(mod)
states
data.frame(val = rle(states)$values, n = rle(states)$lengths) %>% 
  ggplot(aes(val %>% factor, n)) + geom_violin()
# look at the distributions runs of each state
# runs in state 2 generally look to be a bit longer

# model validation
mod %>% plotPR()
# note that there is a fair amount of autocorrelation, and a bit of 
# deviation from the QQ line. There are a couple of things that we can try. 
# 1) coarser time scale (but might shift our interpretation of the states)
# 2) different starting values (in case we're not on the optimum)
# 3) accounting for autocorrelation using markmodmover


# try a coarser time scale
# 4.5 for 4.5 mins
yaps1315 %>% rename(date=top) %>% tempinterp(ts=90*3) -> pike4.5
# plot the two datasets
p1 <- yaps1315 %>% ggplot(aes(x=x, y=y)) + 
  geom_path() + 
  geom_point(aes(x, y), data=pike, col="cadetblue")
p2 <- yaps1315 %>% ggplot(aes(x=x, y=y)) + 
  geom_path() + 
  geom_point(aes(x, y), data=pike4.5, col="tomato")
grid.arrange(p1, p2, ncol = 1)
# prep the new data and fit the model
pike_prep4.5 <- prepData(pike4.5, type="UTM")
mod4.5 <- fitHMM(data = pike_prep4.5, 
              nbStates = 2, 
              stepPar0 = c(sl_init_mean, sl_init_sd),
              anglePar0 = c(ta_init_mean, ta_init_con),
              formula = ~1, 
              stepDist = "gamma", 
              angleDist = "vm")
mod4.5 %>% plotPR()
# reduced the autocorrelation a bit at the later lags! 
# but we still have some at the earlier lags
# suggests that acf is partly because of the interpolation


# try different starting values
# do this for the coarser time scale
sl_init_mean <- sl_init_sd <- runif(2, min(pike_prep4.5$step, na.rm=TRUE), max(pike_prep4.5$step, na.rm=TRUE))
# in the guide it suggests picking an sd of a similar value to the mean 
ta_init_mean <- runif(2, -pi, pi)
ta_init_con <- runif(2, 0, 10)
# note that the order matters! The first parameters for each observation 
# apply to the first state, and so on...
mod_inits2 <- fitHMM(data = pike_prep4.5, 
              nbStates = 2, 
              stepPar0 = c(sl_init_mean, sl_init_sd),
              anglePar0 = c(ta_init_mean, ta_init_con),
              formula = ~1, 
              stepDist = "gamma", 
              angleDist = "vm")
mod_inits2 %>% plotPR() # looks the same
# check how close they are
mod4.5$mle$stepPar
mod_inits2$mle$stepPar
# so this didn't help us (in terms of residuals), 
# parameter values are the same which is a good sign that we are at the global optimum 
# of the likelihood




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




###################################################
### lesson 3: picking between numbers of states ###
###################################################

# so we don't have a great model fit
# we also already thought that there might be a third behaviour in there
# so now lets try adding more states

# check from states 3:6
mods_ac <- list()
mods_ac[["nstates2"]] <- mod_ac
# fit a bunch of models 
for(i in 3:6) mods_ac[[paste("nstates", i, sep="")]] <- fit(pike, N.States=i)
# so we get a couple warnings about our convergence, let's check out which models had problems
lapply(mods_ac, function(x)x@Convergence)
mods_ac[["nstates6"]]<- NULL # can get rid of the ones with bad convergence like so
mods_ac[["nstates5"]]<- NULL
# codes 3, 4, and 5 are okay, anything else isn't

# to choose between we can look at the AIC
lapply(mods_ac, function(x)x@AIC)
# notice that the aic in this case is almost always going down. there is a bunch of research that 
# suggests that when you use aic to select amongst numbers of behavioural states, it often 
# favours the model with more states. so while we can use this as some information in 
# picking how many states we need, it shouldn't be the only information. we should 
# also be looking at the overall model fit (residuals), and thinking about biological relevance
# we can take a look at the deltaAIC
lapply(mods_ac, function(x)x@AIC) %>% unlist() %>% diff()

# 2d plots of step length autocorrelation
par(mfrow=c(2,2))
# h really can affect our perception, level of smoothness (bandwidth)
for(i in 1:3){
  resdens <- MASS::kde2d(head(mods_ac[[i]]@Residuals$Step.Length,-1),
                         tail(mods_ac[[i]]@Residuals$Step.Length,-1),
                         lims = c(-1,1,-1,1), h=0.2)
  image(resdens, col=grey(seq(1,0,length.out = 10)), main = names(mods_ac)[[i]],
        xlab='step length at time t', ylab = 'step length at time t-1')
}
# should look like random scatter
# gets better with more states

# step length qqplots
par(mfrow=c(2,2))
for(i in 1:3){
  qqplot(y = residuals(mods_ac[[i]])$Step.Length,
         x = seq(-1,1,2/nrow(residuals(mods_ac[[i]]))),
         xlab = "theoretical", ylab='predicted', main = names(mods_ac)[[i]])
  abline(a = 0, b = 1, col = "red")
}
# should follow 1-1 line

# turning angle qqplots
par(mfrow=c(2,2))
for(i in 1:3){
  qqplot(y = residuals(mods_ac[[i]])$Deflection.Angle,
         x = seq(-1,1,2/nrow(residuals(mods_ac[[i]]))),
         xlab = "theoretical", ylab='predicted', main = names(mods_ac)[[i]])
  abline(a = 0, b = 1, col = "red")
}
# should follow 1-1 line
# that little divet in the middle is weird, maybe we need some zero inflation? 

par(mfrow=c(2,2))
for(i in 1:3) acf(residuals(mods_ac[[i]])$Step.Length, main = names(mods_ac)[[i]])

# i would say we improve from time step 2 to 3, maybe improve a bit more from 
# time step 3 to 4

# so now we take into account the parameter estimates and the biology of the animal
plot(mods_ac[['nstates3']])
mods_ac[['nstates3']]
states_ac <- viterbiPath(mods_ac[['nstates3']])
data.frame(val = rle(states_ac)$values, n = rle(states_ac)$lengths) %>% 
  ggplot(aes(val %>% factor, n)) + geom_violin()
### state 1
# one turning angle with low scale centered at pi
# paired with low reversion level, and low acf 
# suggests residency/low movement behaviour
### state 2
# one turning angle with medium scale centered at 0
# paired with higher reversion level and higher acf
# lower level of movement, maybe they're slowing down and looking for a good hideout? 
### state 3
# one turning angle with high scale centered at 0
# paired with higher step lengths and high acf
# highly directed movement
### tpm 
# good amount of time spent in each state, but highly unlikely to switch between 
# states 1 and 3
# suggests to me that state 1 is the sit-and-wait behaviour, state 3 is directed travel 
# between places, and state 2 is exploratory/transitioning behaviour between the other two states
# always good to be able to validate these behaviours (e.g. cameras)
### states
# stay in state 1 a lot longer than others, also suggests sitting and waiting
# i think unlikely to get the actual burst behaviour 
# (too quick and won't travel far enough and won't stay in it long enough)


plot(mods_ac[['nstates4']])
mods_ac[['nstates4']]
# state 1: centered at 0 with low scale, plus v low step length reversion level and no acf
# state 2: centeered at 0 with medium scale, with slightly larger reversion level and low acf
# state 3: centered at pi, medium scale, similar reversion level ti state 2 and a bit of acf 
# state 4: centered at 0, high scale, large reversion level and acf
# tpm getting harder to interpret
states_ac <- viterbiPath(mods_ac[['nstates4']])
data.frame(val = rle(states_ac)$values, n = rle(states_ac)$lengths) %>% 
  ggplot(aes(val %>% factor, n)) + geom_violin()
par(mfcol=c(2,1))
plot(mods_ac[['nstates3']], y='locations')
plot(mods_ac[['nstates4']], y='locations')
# bottom line is that you need to be able to explain the behaviours, so since i 
# am at my limit of pike knowledge i would pick three states





#############################################
### lesson 4: fitting to multiple animals ###
#############################################


########## okay now we're going to bring in the second track and fit a collective movement model
# going to do this with moveHMM
# basically, we're fitting the same model to two tracks simultaneously
# borrowing information across tracks to estimate parameters
# assuming that the animals are moving in the same way
# take both pike, interpolate them, and add them to the same dataset with an ID column
yaps1315 %>% rename(date=top) %>% tempinterp(ts=90) -> pike1315
yaps1335 %>% rename(date=top) %>% tempinterp(ts=90) -> pike1335
rbind(pike1315, pike1335) %>% 
  mutate(ID = c(rep(1315, nrow(pike1315)), rep(1335, nrow(pike1335)))) -> pike
head(pike)

# now prep them like we did before
pike_prep <- prepData(pike, type="UTM")
head(pike_prep) 
# it's reordered our data
plot(pike_prep)
# plots for each animal now

# based on the previous analysis, we'll assume that there are three states
par(mfrow=c(2,1))
hist(pike_prep$step, breaks=20, freq=FALSE)
curve(dgamma(x,0.8,rate=1), n=200, add=TRUE, col="royalblue", lwd=2)
curve(dgamma(x,1.5,rate=0.4), n=200, add=TRUE, col="cadetblue", lwd=2)
curve(dgamma(x,1.2,rate=0.02), n=200, add=TRUE, col="navyblue", lwd=2) 
hist(pike_prep$angle, freq=FALSE, ylim=c(0, 0.7))
curve(circular::dvonmises(x,pi,0.3), n=200, add=TRUE, col="royalblue", lwd=2)
curve(circular::dvonmises(x,0,1), n=200, add=TRUE, col="cadetblue", lwd=2)
curve(circular::dvonmises(x,0,3), n=200, add=TRUE, col="navyblue", lwd=2)

# mean = shape/rate
# sd = alpha^(1/2)/beta
sl_init_mean <- c(0.8/1, 1.5/0.4, 1.2/0.02)
sl_init_sd <- c(sqrt(0.8)/1, sqrt(1.5)/0.4, sqrt(1.2/0.02))
ta_init_mean <- c(pi, 0, 0)
ta_init_con <- c(0.3, 1, 3)
# remember order matters!
mod2pike <- fitHMM(data = pike_prep, 
              nbStates = 3, 
              stepPar0 = c(sl_init_mean, sl_init_sd),
              anglePar0 = c(ta_init_mean, ta_init_con),
              formula = ~1, 
              stepDist = "gamma", 
              angleDist = "vm")
plot(mod2pike)
mod2pike
# state 1: low step length, v flat turning angle distribution
# state 2: v high step length, concentrated ta dist
# state 3: medium step length, concentrated ta dist
# suggests one residency state and two movement states at different speeds

mod2pike %>% plotPR()
# still a fair amount of autocorrelation in the step length pseudoresiduals
# so probably best to use the carHMM
# but there currently isn't direct functionality for incorporating multiple animals 
# in one movement model
# the machinery is there because of the grouping (it's the same idea), so you might 
# be able to rig the pacakge to do so, but that's above this tutorial 

# can try fitting a model with four states to see if this improves
# at this point i'll just randomly pick some starting values for the fourth state
sl_init_mean <- c(0.8/1, 1.5/0.4, 1.2/0.02, runif(1, 0, 5))
sl_init_sd <- c(sqrt(0.8)/1, sqrt(1.5)/0.4, sqrt(1.2/0.02), runif(1, 0.1, 5))
ta_init_mean <- c(pi, 0, 0, runif(1, -pi, pi))
ta_init_con <- c(0.3, 1, 3, runif(1, 0.1, 10))
mod2pike4states <- fitHMM(data = pike_prep, 
              nbStates = 4, 
              stepPar0 = c(sl_init_mean, sl_init_sd),
              anglePar0 = c(ta_init_mean, ta_init_con),
              formula = ~1, 
              stepDist = "gamma", 
              angleDist = "vm")
mod2pike4states %>% plotPR()
# doesn't really improve the acf
mod2pike4states

# with moveHMM, you can use the AIC function to compare models
AIC(mod2pike, mod2pike4states) 

# again, this suggests that we should use the four-state model
# but if you plot the 4 state model, all of the states really appear on this gradation
# between short steps paired with random turning angles, to long steps paired with directed
# angles, so if the model fit isn't improving significantly in terms of the residuals
# (which imo it isn't significantly) and if you don't have a reasonable explanation for the states, 
# then it might be better to use a more parsimonious model 



# couple of things we haven't gone over:
#### zero inflation
# zero inflation is used when you have step lengths of zero
# the common distributions for step length can't include a value of zero, 
# so you have to add this factor if you have observations where the animal truly didn't move
# you can do step length zero inflation with moveHMM and markmodmover, can also do 
# angle zero inflation with markmodmover
#### covariates
# the covariates are useful for determining what factors might cause an animal to switch
# between states - you can look at extrinsic ones (like water temperature) or 
# intrinsic ones (like depth of the animal). 
#### fitting to messy data
# key assumption of hmms is that our data are highly accurate
# fitting our hmms to messier data (in my experience, VPS data) can mean that you cannot 
# fully attribute your results to your animal movement alone, they might in part be caused 
# by the error in the track


#################### Take-Aways ###################
# lots of subjective choices to fitting these models
# important to document your reasoning
# ideally we account for measurement error and estimate behavioural 
# states in one complete model, but that can be really hard to do!

