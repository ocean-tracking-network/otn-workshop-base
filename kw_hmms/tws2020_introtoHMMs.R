############## to do 
### lesson 1: fit an HMM; picking time step; picking starting values, interpretation, assessing model fit
### lesson 2: accounting for acf
### lesson 3: picking between numbers of states
### lesson 4: fitting to multiple animals
### lesson 5: fitting to seemingly messier data is hard

# i always start by removing all objects and setting my working directory
rm(list=ls())
setwd("~/Desktop/ideasOTNtws2020code/kw_hmms")

# install the packages
install.packages("TMB")
devtools::install_github("TheoMichelot/moveHMM", build_vignettes=TRUE)
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
load("dataforHMMintro.rda")
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
# velocity is the instantaneous velocity (of the tag, or of sound?)

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
# pike are burst swimmers, so we would expect to see at least two behaviours, a sit-and-wait 
# and a burst/hunt behaviour, but there might be a third behaviour in here 


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
# pretty uniformly distributed, makes sense (nature of pings)
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
# angle is the turning angle - these are in radians (multiple by 180/pi if you want degrees)
# note a couple of NAs, because it takes two locations to calculate a step length and 
# three to calculate a turning angle. Also note the alignment of these NAs suggests that
# the step length from times t-1 to t and the angle between times t-1, t, and t+1 will 
# be informing the same state

# now let's take a look at the distributions
# moveHMM has a generic plotting function for the processed data
plot(pike_prep)
# i like to look at the densities and histograms
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
# there is a great guide from Théo Michelot and Roland Langrock: https://cran.r-project.org/web/packages/moveHMM/vignettes/moveHMM-starting-values.pdf
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
# sd = alpha^(1/2)/beta
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
# interpret parameters

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
# note that there is a fair amount of autocorrelation, and a little bit of 
# deviation from the QQ line. There are a couple of things that we can try. 
# 1) coarser time scale (but might shift our interpretation of the states)
# 2) different starting values (in case we're not on the optimum)
# 3) accounting for autocorrelation using markmodmover


# try a coarser time scale
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



# try different starting values
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
# so this didn't help us (in terms of residuals), but it is a good sign that we are at the optimum of the likelihood




####################################
### lesson 2: accounting for acf ###
####################################

# to do this we will use markmodmover
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
library(rgdal)
# world <- readOGR(dsn="~/Documents/Shapefiles", layer="World") #natural earth
yaps1315 %>%
  dplyr::select(x, y) %>% 
  as.matrix() %>% 
  SpatialPoints(proj4string=CRS("+init=epsg:32632")) -> pike_proj
pike_proj %>% spTransform(CRS("+proj=longlat")) -> pike_unproj
plot(world, xlim=c(0, 11), ylim=c(50, 60), col="cadetblue")
points(pike_unproj, type='l', lwd=5, col="tomato") #there we are in Denmark!
# (i typically plot it to make sure it worked)
# note that select fails by itself because it's overwritten by MASS
# detach("package:MASS", unload=TRUE) doesn't work bc required by CircStats, which is required by moveHMM

# so now we use the data4M() function to prep the data
# it has a bit of flexibility in the naming of the data, i use the shortest possible 
# so i renamed to lonand lat
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
pike@Movement.Data$Movement.Data$Step.Length %>% boxplot.stats()
pike4viz <- pike
pike4viz@Movement.Data$Movement.Data <- pike4viz@Movement.Data$Movement.Data %>% filter(Step.Length < 2)
plot(pike4viz, y="data")
# They are both 2 dimensional kernal density estimators (using MASS::kde2d)
# the first one is basically a kde of each of the step vectors centered at 0
# the second is a kde of the step length at time t vs at time t-1, which 
# can be used to help figure out what kind of model to fit - if it looks 
# like a continuous line along y=x, then use the carHMM. if it looks like 
# a series of droplets along y=x, then use a regular HMM. See Lawler et al. 2019. 
# these ones are a bit hard to read but i would say suggestive of ac

# now that the data are in the correct format, we can fit the model!
# with this model, starting values are picked randomly
# it also uses a wrapped cauchy for a turning angle distribution
# but you can pick between a gamma and log normal for the step lengths (gamma is default)
mod_ac <- fit(pike)
mod_ac
# note a couple of things
# wrapped cauchy distribution here is parameterized with a scale parameter between 0 and 1
# higher value -> more concentrated
# mean of the gamma distribution is mean = (1-ac)*reversion.level + ac*previous.step.length

# state definitions have switched
mod
# in previous models, the longer step lengths were associated with state 1, now associated with state 2
# tpms are pretty similar tho!
states_ac <- viterbiPath(mod_ac)
data.frame(val = rle(states)$values, n = rle(states)$lengths) %>% 
  ggplot(aes(val %>% factor, n)) + geom_violin()
# looks pretty similar

# now we take a look at the model diagnostics
plot(mod_ac)
par(mfrow=c(2,1))
pseudoRes(mod)$stepRes %>% acf(main="moveHMM", na.action=na.pass)
mod_ac@Residuals$Step.Length %>% acf(main="markmodmover")
# acf is pretty reduced, but you can still see some
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
for(i in 3:7) mods_ac[[paste("nstates", i, sep="")]] <- fit(pike, N.States=i)
# so we get a couple warnings about our convergences, let's check out which models had problems
lapply(mods_ac, function(x)x@Convergence)
mods_ac[["nstates7"]]<- NULL # get rid of the ones with bad convergence like so
# codes 3, 4, and 5 are okay, anything else isn't

lapply(mods_ac, function(x)x@AIC)
# notice that the aic in this case is almost always going down. there is a bunch of research that 
# suggests that when you use aic to select amongst numbers of behavioural statess, it often 
# favours the model with more states. so while we can use this as some information in 
# picking how many states we need, it shouldn't be the only information. we should 
# also be looking at the overall model fit (residuals), and thinking about biological relevance
# we can take a look at the deltaAIC
lapply(mods_ac, function(x)x@AIC) %>% unlist() %>% diff()

# 2d plots of step length autocorrelation
par(mfrow=c(3,2))
# h really can affect our perception, level of smoothness (bandwidth)
for(i in 1:5){
  resdens <- MASS::kde2d(head(mods_ac[[i]]@Residuals$Step.Length,-1),
                         tail(mods_ac[[i]]@Residuals$Step.Length,-1),
                         lims = c(-1,1,-1,1), h=0.25)
  image(resdens, col=grey(seq(1,0,length.out = 10)), main = names(mods_ac)[[i]],
        xlab='step length at time t', ylab = 'step length at time t-1')
}
dev.off()

# step length qqplots
par(mfrow=c(3,2))
for(i in 1:5){
  qqplot(y = residuals(mods_ac[[i]])$Step.Length,
         x = seq(-1,1,2/nrow(residuals(mods_ac[[i]]))),
         xlab = "theoretical", ylab='predicted', main = names(mods_ac)[[i]])
  abline(a = 0, b = 1, col = "red")
}
dev.off()

# turning angle qqplots
par(mfrow=c(3,2))
for(i in 1:5){
  qqplot(y = residuals(mods_ac[[i]])$Deflection.Angle,
         x = seq(-1,1,2/nrow(residuals(mods_ac[[i]]))),
         xlab = "theoretical", ylab='predicted', main = names(mods_ac)[[i]])
  abline(a = 0, b = 1, col = "red")
}
dev.off()

par(mfrow=c(3,2))
for(i in 1:5) acf(residuals(mods_ac[[i]])$Step.Length, main = names(mods_ac)[[i]])
dev.off()

# i would say we improve from time step 2 to 3, maybe improve a bit more from 
# time step 3 to 4, and then don't improve after that
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
# lower level of movement, maybe they're looking for a good hideout? 
### state 3
# one turning angle with high scale centered at 0
# paired with higher step lengths and high acf
# highly directed movement
### tpm 
# good amount of time spent in each state, but if you're in either state 2 or 3
# then you are more likely to switch between those
# suggests to me that state 1 is the sit-and-wait behaviour, state 3 is directed travel 
# between places, and state 2 is exploratory behaviour
# always good to be able to validate these behaviours
### states
# stay in state 1 a lot longer than others, also suggests sitting and waiting
# i think unlikely to get the actual burst behaviour 
# (too quick and won't travel far enough and won't stay in it long enough)


plot(mods_ac[['nstates4']])
mods_ac[['nstates4']]
# state 1: centered at pi with low scale, plus v low step length reversion level and acf
# state 2: centeered at pi with medium scale, with sligthly larger reversion level and no acf
# state 3: centered at 0, medium scale, larger reversion level and a bit of acf
# state 4: centered at 0, high scale, large reversion level and acf
states_ac <- viterbiPath(mods_ac[['nstates4']])
data.frame(val = rle(states_ac)$values, n = rle(states_ac)$lengths) %>% 
  ggplot(aes(val %>% factor, n)) + geom_violin()
par(mfcol=c(2,1))
plot(mods_ac[['nstates3']], y='locations')
plot(mods_ac[['nstates4']], y='locations')
# states 1 and 4 are basically the same as the old states 1 and 3, but old state 2 
# has been split into new state 2 and 3
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
# state 1: low step length, flat turning angle distribution
# state 2: v high step length, fairly concentrated ta dist
# state 3: medium step length, medium concentrated ta dist

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
# doesn't improve the acf
mod2pike4states

# with moveHMM, you can use the AIC function to compare models
AIC(mod2pike, mod2pike4states) 

# again, this suggests that we should use the four-state model
# but if you plot the 4 state model, all of the states really appear on this gradation
# between short steps paired with random turning angles, to long steps paired with directed
# angles, so if the model fit isn't improving significantly in terms of the residuals
# (which it isn't) and if you don't have a reasonable explanation for the states, 
# then it might be better to use a more parsimonious model 

# two things we haven't gone over is covariates and zero inflation
# zero inflation is used when you have step lengths of zero
# the common distributions for step length can't include a value of zero, 
# so you have to add this factor if you have observations where the animal truly didn't move
# the covariates are useful for determining what factors might cause an animal to switch
# between states - you can look at extrinsic ones (like water temperature) or 
# intrinsic ones (like depth of the animal). 




###########################################################
### lesson 5: fitting to seemingly messier data is hard ###
###########################################################


# now let's switch gears and try to analyze some more data
# the following data come from Jan Davidsen, who is studying the effect of a whole-lake 
# treatment on the movement of the local crayfish
# the data were triangulated using Thelma pinpoint (not a SSM like YAPS)
# let's check them out 
# cray34 <- read.csv("~/Desktop/Davidsen/KyvatnetPinpoint/S256_ID34.csv")
head(cray34)
names(cray34) <- c("id", "date", "lat", "lon", "data", "depth", "xutm", "yutm", "utmzone", "snrdb")
# the recs
recs <- data.frame(
  rec = c(141, 146, 147, 148, 149, 150, 273, 274),
  lon = c(10.3424800, 10.3437386, 10.3424962, 10.3424904, 10.3406224, 10.3398702, 10.3384087, 10.3402024),
  lat = c(63.4063750, 63.4053460, 63.4046390, 63.4037960, 63.4030930, 63.4040040, 63.4046710, 63.4058460)
)
plot(lat~lon, data=cray34, type='l', xlim=c(10.338, 10.344), ylim=c(63.4030, 63.406))
points(lat~lon, data=cray34, type='p')
points(lat~lon, data=recs, pch=20, col='dodgerblue', cex=2)
# these receivers were all placed around the edge of the lake (they basically trace the shape)
# the crayfish is in the shallow zones
# these bunches of locations kind of look like they might be more tech related than bio related
# i think typically the algorithms used to calculate these locations (when not a SSM)
# look at the intersection of three detections tdoa, so it might be that the cray fish are 
# only really being detected where those intersections are more likely

# try to pick a time step
# have to set the date to an as.posix
cray34$date <- as.POSIXct(as.character(cray34$date), "%Y-%m-%dT%H:%M:%SZ", tz="GMT")
difftime(cray34$date[-1], cray34$date[-nrow(cray34)], units="secs") %>% as.numeric() %>% density() %>% plot()
# woof, density plot doesn't show much because there are clearly some outliers (large data gaps)
plot(lon~date, data=cray34) 
# huge gap, over a month, we can cut it in two at Nov 1
cray34 %>% 
  mutate(idx = (date < as.POSIXct("2016-11-01 00:00:00", "%Y-%m-%d %H:%M:%S", tz="GMT"))) %>% 
  ggplot(aes(x=lon, y=lat, col=idx)) + geom_path()+ geom_point()


cray34bn1 <- cray34 %>% filter(date < as.POSIXct("2016-11-01 00:00:00", "%Y-%m-%d %H:%M:%S", tz="GMT"))
# in this case, only look at the points before nov 1
# in these HMMs we assume that the data are highly accurate
# we are obviously breaking that assumption so we need to be aware of this
# the locations after nov 1 have a ton of error, and don't really look like they have 
# multiple states, which is why we will choose the locations before nov 1

# let's look at the temporal distribution now
difftime(cray34bn1$date[-1], cray34bn1$date[-nrow(cray34bn1)], units="secs") %>% as.numeric() %>% density() %>% plot()
difftime(cray34bn1$date[-1], cray34bn1$date[-nrow(cray34bn1)], units="secs") %>% as.numeric() %>% boxplot()
plot(lon~date, data=cray34bn1) 
# still kind of a rough distribution through time, lots of outliers
# we still have some gaps
# if we use carhmm, it will split up the track automatically based on the group cutoff


cray34bn1[c("date", "lon", "lat")] %>% 
  data4M() -> cray
cray
# taking a look at the time steps, the distribution is obviously skewed (we knew that already)
# the median is therefore a better measure of the center of the distribution
cray <- interpolate(cray, Time.Step=0.08) # takes the time step in hours
# 83 groups, we'll see how this goes
mod <- fit(cray, N.States=2)
# we get an error: optimization did not work, try increasing max.tries
# max tries tries to fit the model different times by randomly sampling the starting values 
mod <- fit(cray, max.tries=100, N.States=2)
# even 100 tries doesn't work


# try increasing the time step and the group cutoff to decrease the number of groups
# increasing the time step in this case would smooth out the track
# decreasing the number of groups would help if there aren't that many data within each group
crayt1 <- interpolate(cray, Time.Step=1, Group.Cutoff = 4) 
crayt1
mod <- fit(crayt1, N.States=2)
# still doesn't work 


# i played around a bit, and I could get the model to fit for the 100:900 locations 
# with a large time step and group cut off
cray34bn1[100:900,c("date", "lon", "lat")] %>% 
  data4M() -> cray
cray <- interpolate(cray, Time.Step=1, Group.Cutoff = 4) 
cray
mod <- fit(cray, max.tries=100, N.States=2)
mod
plot(mod)
# residuals might look fine, but the mod itself doesn't really give us any information
# tpm is 0.5 all around

# one thing i just want to show quickly is that you can set the acf=0
# in markmodmover (fitting similar model to moveHMM)
# you do that with the Use.HMM functionality
# this is useful if you want to split your tracks into groups but don't need the acf
mod <- fit(cray, Use.HMM=TRUE, N.States=2)
mod %>% plot()
# but the acf in the step lengths is now present, so i would use the carhmm



#################### Take-Aways ###################
# lots of subjective choices to fitting these models
# important to document your reasoning
# fitting to messy data is hard!

