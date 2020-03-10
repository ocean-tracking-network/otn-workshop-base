---
title: Fitting Hidden Markov Models with moveHMM
teaching: 30
exercises: 0
questions:
        - "What can applying hidden markov models to my movement data using moveHMM tell me about the behaviour of my animals?"
objectives:
        - "Fit a hidden markov model."
        - "Picking an appropriate time step."
        - "Picking starting values."
        - "Interpretation of model results."
        - "Assessing model fit."
---

### Lesson 1 - fit an HMM

~~~
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
~~~
{:.language-r}

Let's take a look at all of the variables in our dataset.
~~~
head(yaps1315)
~~~
{:.language-r}

Here x is the Easting, and y is the Northing, that means we're projected, it's in UTM32N - epsg32632 (projection)
  * sd_x and sd_y are the standard deviations associated with the YAPS model
  * top is the time of the ping
  * nobs is the number of receivers that detected each ping
  * velocity is the instantaneous speed of sound

Let's first start just by plotting the data. Since we're looking at predicted values from a model, I would also like to look at a confidence interval around the predictions (normally distributed.
Let's just use 95% CI)

~~~
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
~~~
{:.language-r}

Neither of these confidence intervals look very wide, which is a good sign

I also like to take a look at each location axis against time, which tells me a bit about whether they are continuously spaced, whether there are any gaps, and a bit about the behaviours

~~~
plot(x ~top, data=yaps1335, type="p")
plot(y ~top, data=yaps1335, type="p")
~~~
{:.language-r}

In these first two plots, we see no gaps, and nothing really looks out of the ordinary, although there is almost a cyclical change, and the spread gets wider as time goes on

~~~
plot(x ~top, data=yaps1315, type="p")
plot(y ~top, data=yaps1315, type="p")
~~~
{:.language-r}

These next two plots show some interesting behaviour: it looks like the animal might be showing some clear residency behaviour where it's not changing it's position at all and then shows some clear directed movement.

Pike are burst swimmers, so we know of at least three behaviours, a sit-and-wait, a burst, and a likely movement between the sit-and-wait spots, but we might not be able to pick up the burst behaviour because it's really quick.

### Movement and Behavioural States

The first thing that we need to do is interpolate the data onto a regular time interval in order to do this, we need to pick a time step there are a couple of different schools of thought about this one is to pick a time step that will give you a number of interpolated locations close to the number of observations that you have

Let's try that first, so we need to take a look at the distribution of the temporal intervals. When working with time, note that just the regular `diff` function will pick the units for you. If you want to specify the units then you need to use `difftime` and supply two vectors.

~~~
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

~~~
{:.language-r}

Now that we have locations occuring in regular time, the next step is to decompose the track into step lengths and turning angles. There are a few ways to do this, and different packages do it in different ways. It's really important to understand your projection (or lack thereof) with moveHMM, we need to use the `prepData` function.

~~~
pike_prep <- prepData(pike, type="UTM")
# type can be either UTM or LL - use UTM for easting/northing (because we are projected)
# use coordNames argument if your locations are named other than the default (x, y)
head(pike_prep)
tail(pike_prep)

~~~
{:.language-r}

Here we see a couple of things -
  * there is an animal ID that is automatically created - we'll get back to this later
  * step is the step length - these are in m because our original locations are in m
  * angle is the turning angle - these are in radians (multiply by 180/pi if you want degrees)
note a couple of NAs, because it takes two locations to calculate a step length and three to calculate a turning angle. Also note the alignment of these NAs suggests that the step length from times t-1 to t and the angle between times t-1, t, and t+1 will be informing the same state

Now let's take a look at the distributions. `moveHMM` has a generic plotting function for the processed data
~~~
plot(pike_prep)
# i also like to look at the densities and histograms side by side
par(mfrow=c(2,2))
density(pike_prep$step, na.rm=TRUE) %>% plot(main="Step Length Density")
hist(pike_prep$step, main = "Step Length Histogram")
density(pike_prep$angle, na.rm=TRUE) %>% plot(main="Turning Angle Density")
hist(pike_prep$angle, main = "Turning Angle Histogram")
~~~
{:.language-r}

Our objective is to look for multiple states. In modelling terms, this means that we are assuming that these observations shouldn't be modelled with just one underlying probability distribution, but multiple i.e., these empirical densities actually contain multiple parametric densities within them.

In an HMM, we want to estimate these multiple densities, and the states that relate to them.
An optimization routine is an algorithm that seeks to find the optimum from a function. `moveHMM` uses `nlm`, `markmodmover` uses `nlminb`. In order to optimize a function, you need to have starting values. If your function is bumpy, then it can be harder to find a global optimum, so you want to be careful about your choice of starting values, and it's a good idea to check multiple sets

To pick starting values, I like to overlay densities on my histograms. For `moveHMM`, the default densities are **gamma (step length)** and **von mises (turning angle)**


~~~
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
~~~
{:.language-r}

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
~~~
{:.language-r}
