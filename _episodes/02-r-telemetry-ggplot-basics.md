---
title: Making basic plots using ggplot
teaching: 15
exercises: 0
questions:
      - "How do I make more sophisticated plots in ggplot?"
objectives:
      - "Become familiar with ggplot and dplyr's methods to summarize and plot data"
      - "Explore how ggplot aesthetics and geometry work together"
keypoints:
      - "You can feed output from dplyr's data manipulation functions into ggplot using pipes."
      - "Plotting various summaries and groupings of your data is good practice at the exploratory phase, and dplyr and ggplot make iterating different ideas straightforward."
---


### Background

`ggplot2` takes advantage of tidyverse pipes and chains of data manipulation as well as separating the aesthetics of the plot (what are we plotting) from the styling of the plot (how should we show it?), in order to produce readable and malleable plotting code.

general formula `ggplot(data = <DATA>, mapping = aes(<MAPPINGS>)) + <GEOM_FUNCTION>()`

~~~
# Assign plot to a variable
seaTroutplot <- ggplot(data = seaTrout, 
                       mapping = aes(x = lon, y = lat)) #can assign a base plot to data

#Draw the plot
seaTroutplot + 
  geom_point(alpha=0.1, 
             color = "blue") #layer whatever geom you want onto your plot template
                             #very easy to explore diff geoms without re-typing
                             #alpha is a transparency argument in case points overlap
~~~
{: .language-r}


### Exploratory Plots

Let's start with a practical example. First we'll plot the basic shape of this data summary, then we'll look at applying more style choices to improve our plot's readability.
~~~
# monthly longitudinal distribution of salmon smolts and sea trout

seaTrout %>%
  group_by(m=month(DateTime), tag.ID, Species) %>% #make our groups
  summarise(mean=mean(lon)) %>% #mean lon
  ggplot(aes(m %>% factor, mean, colour=Species, fill=Species))+ #the data is supplied, but no info on how to show it!
  geom_point(size=3, position="jitter")+   # draw data as points, and use jitter to help see all points instead of superimposition
  coord_flip()+   #flip x y    
  scale_colour_manual(values=c("grey", "gold"))+  # change the color palette to reflect species a bit better
  scale_fill_manual(values=c("grey", "gold"))+ 
  geom_boxplot()+ #another layer
  geom_violin(colour="black") #aaaaaand another layer

~~~
{: .language-r}

After we apply all the styling, our grouped time factor's on the Y axis to highlight the longitudinal change that we're showing on the X axis, and we're seeing box plots and violins on top of the 'raw' data points to provide additional context. We've also made a few style choices to ensure we can tease apart all these overlapping plots a bit better.


There are other ways to present a summary of data like this that we might have chosen. `geom_density2d()` will give us a KDE for our data points and give us some contours across our chosen plot axes.
~~~
seaTrout_full %>% #doesnt work on the subsetted data, back to original dataset for this one
  group_by(m=month(DateTime), tag.ID, Species) %>%
  summarise(mean=mean(lon)) %>%
  ggplot(aes(m, mean, colour=Species, fill=Species))+
  geom_point(size=3, position="jitter")+
  coord_flip()+
  scale_colour_manual(values=c("grey", "gold"))+
  scale_fill_manual(values=c("grey", "gold"))+
  geom_density2d(size=2, lty=1) #this is the only difference from the plot above 
~~~
{: .language-r}

Here we start to potentially see why we might like to use multiple plots for each subset, or facets, for our two distinct species, as they're hard to see on top of one another in this way. Switching to stat_density_2d will fill in my levels (and obliterate my ability to see the underlying data points). I'm also going to use `labs()` to properly label my axes.

~~~
seaTrout %>% #maybe try with full dataset seaTrout1 as well, up to you
  group_by(m=month(DateTime), tag.ID, Species) %>%
  summarise(mean=mean(lon)) %>%
  ggplot(aes(m, mean))+
  stat_density_2d(aes(fill = stat(nlevel)), geom = "polygon")+ #new plot type
  geom_point(size=3, position="jitter")+
  coord_flip()+
  facet_wrap(~Species)+ #faceting our plot by species! we already grouped them
  scale_fill_viridis_c() +
  labs(x="Mean Month", y="Longitude (UTM 33)") #axis labeling
~~~
{: .language-r}

Facets are a great way to highlight differences across your groups, and the most obvious next choice for a grouping is by individual tagged animal. Be aware of how many plots you are going to end up with!

~~~
# per-individual density contours - lots of facets!
seaTrout %>%
  ggplot(aes(lon, lat))+
  stat_density_2d(aes(fill = stat(nlevel)), geom = "polygon")+
  facet_wrap(~tag.ID)
~~~
{: .language-r}

So reminder, this is all just exploratory work so far. Using the big individuals plot here, we could identify interesting individuals to subset away for further exploration, or pick out the potential non-survivors and subset them away from the pack. But we've worked mostly with summaries of movement data so far, taking advantage of what we know about our domain without actually looking at it yet. Next we'll do something a bit more spatially-aware.
