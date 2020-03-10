---
title: Choosing Between Numbers of States
teaching: 30
exercises: 0
---

~~~
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
~~~
{:.language-r}
