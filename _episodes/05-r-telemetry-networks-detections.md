---
title: Network analysis using detections of animals at stations
teaching: 15
exercises: 0
questions:
      - "How do I prepare my data in order to apply network analysis?"
---

One of the more popular analysis domains for movement data has been network analysis. Networks are a system of nodes, and the edges that connect them. There are a few ways to think about animal movement data in this context, but perhaps an obvious one, that we've set ourselves up to use via our previous data exploration, is considering the receiver locations as nodes, and the animals travel between them as edges. More trips between receivers, larger and more significant edges. More trips to a receiver from the rest of the network, more centrality for that receiver 'node'.

~~~
# 5.1: Networks are just connections between nodes and we can draw a simple one using animals traveling between receivers.

st %>%
  group_by(Species, lon, lat, llon, llat) %>%       # we handily have a pair of locations on each row from last example to group by
  summarise(n=n()) %>%                              # count the number of rows in each group
  ggplot(aes(x=llon, xend=lon, y=llat, yend=lat))+  # xend and yend define your segments
  geom_segment()+geom_curve(colour="purple")+       # and geom_segment() and geom_curve() will connect them
  facet_wrap(~Species)+
  geom_point()                                      # draw the points as well to make them clear.

~~~
{: .language-r}

So `ggplot` will show us our travel between nodes using `xend` and `yend`, and we can choose a couple ways to display those connections using `geom_segment()` and `geom_curve()`. Splitting on species can show us the different ways each species uses the network, but the scale of the values of edges and nodes is hard to differentiate. Let's switch our plot scale for the edges to a log scale.

~~~
st %>%
  group_by(Species, lon, lat, llon, llat) %>%
  summarise(n=n()) %>%
  ggplot(aes(x=llon, xend=lon, y=llat, yend=lat, size=n %>% log))+
  geom_point() + # Put this on the bottom of the plot.
  geom_segment()+geom_curve(colour="purple")+
  facet_wrap(~Species)
~~~
{: .language-r}

 So we pass n to the log function in our argument to `aes()`, and that gives us a much clearer context for which edges are dominating. Speaking of adding context, let's bring back `bplot` as our backdrop for this and see where our receivers are geospatially.


~~~
bplot+ # we saved this earlier when doing bathymetry plotting
  geom_segment(data=st %>%
                 group_by(Species, lon, lat, llon, llat) %>%
                 summarise(n=n()),
               aes(x=llon, xend=lon, y=llat, yend=lat, size=n %>% log, alpha=n %>% log), inherit.aes=F)+ # bplot has Z, nothing else does, so inherit.aes=F to ignore missing parent aesthetic values
  facet_wrap(~Species)  # we also scale alpha because we're going to force a lot of these relationship lines on top of one another with this method.

~~~
{: .language-r}

So to keep the map visible and to see the effect of lines that overlap heavily because we're forcing it to spatial bounds, we have alpha being set to log(n) as well, alpha is our transparency setting. We also have to leverage inherit.aes=F again, because our network values don't have a Z axis like our bplot.

You can take things further into the specifics of network analysis with this data and the `igraph` and `ggraph` packages (but it's too big a subject for this tutorial!), but when building the source data for it as we've done here, you would want to decide whether you're intending to see trends in individuals, species, by other variables, whether the regions are your nodes or individuals are your nodes, whether a few highly detected individuals are providing most of the story in a summary like the one we made here, etc.
