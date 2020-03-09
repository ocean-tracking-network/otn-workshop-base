---
title: Animating ggplot with gganimate and gifski
teaching: 10
exercises: 0
questions:
        - "How do I animate my tracks?"
objectives:
        - "Isolate one individual and animate his paths between receivers using gganimate and gifski."
---

You can extend `ggplot` with `gganimate` to generate multiple plots, and stitch them together into an animation. In the `glatos` package, we'll use ffmpeg to make videos out of these static images, but you can also generate a gif using `gifski`.

~~~
## Chapter 6: Animating plots ####

# Let's pick one animal to follow
st1<-st %>% filter(tag.ID=="A69-1601-30617") # another great time to check hydration levels

an1<-bgo %>%
  fortify %>%
  ggplot(aes(x, y, fill=z))+
  geom_raster()+
  scale_fill_etopo()+
  labs(x="Longitude", y="Latitude", fill="Depth")+
  theme_classic()+
  theme(legend.key.width=unit(5, "cm"), legend.position="top")+
  theme(legend.position="top")+
  geom_point(data=st %>%
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


Notably: we're doing a lot of portage! The perils of working in a winding river system, or around land masses is that our straight-line interpolations plain look silly when you animate them this way.

Later we'll use the `glatos` package to help us dodge land masses better in our transitions.
