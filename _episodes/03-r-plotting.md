---
title: Intro to Plotting
teaching: 15
exercises: 10
questions:
    - "How do I plot my data?"
    - "How can I plot summaries of my data?"
objectives:
    - "Learn how to make basic plots with ggplot2"
    - "Learn how to combine dplyr summaries with ggplot2 plots"
keypoints:
    - "You can feed output from dplyr's data manipulation functions into ggplot using pipes."
    - "Plotting various summaries and groupings of your data is good practice at the exploratory phase, and dplyr and ggplot make iterating different ideas straightforward."	  
---

### Background

`ggplot2` takes advantage of tidyverse pipes and chains of data manipulation as well as separating the aesthetics of the plot (what are we plotting) from the styling of the plot (how should we show it?), in order to produce readable and malleable plotting code.

general formula `ggplot(data = <DATA>, mapping = aes(<MAPPINGS>)) + <GEOM_FUNCTION>()`
~~~
library(ggplot2) #tidyverse-style plotting, a very customizable plotting package


# Assign plot to a variable
lamprey_dets_plot <- ggplot(data = lamprey_dets,
                  mapping = aes(x = deploy_lat, y = deploy_long)) #can assign a base plot to data

# Draw the plot
lamprey_dets_plot +
  geom_point(alpha=0.1,
             colour = "blue")
#layer whatever geom you want onto your plot template
#very easy to explore diff geoms without re-typing
#alpha is a transparency argument in case points overlap


~~~
{: .language-r}

### Basic plots

You can build your plots iteratively, without assigning to a variale as well.
~~~

lamprey_dets %>%  
  ggplot(aes(deploy_lat, deploy_long)) + #aes = the aesthetic/mappings. x and y etc.
  geom_point() #geom = the type of plot

lamprey_dets %>%  
  ggplot(aes(deploy_lat, deploy_long, colour = animal_id)) + #colour by individual! specify in the aesthetic
  geom_point()

#anything you specify in the aes() is applied to the actual data points/whole plot,
#anything specified in geom() is applied to that layer only (colour, size...). sometimes you have >1 geom layer so this makes more sense!


~~~
{: .language-r}

### Challenge

Try combining with `dplyr` functions in this challenge!
~~~
#Challenge 7: try making a scatterplot showing the lat/long for animal "A69-1601-1363", coloured by detection array

#Question: what other geoms are there? Try typing `geom_` into R to see what it suggests!
~~~
{: .language-r}

> ## Plotting and dplyr Challenge
>
> Combine dplyr functions to solve this challenge.
>
> Try making a scatterplot showing the lat/long for animal "A69-1601-1363", coloured by detection array.
>
>  What other geoms are there? Try typing 'geom_' into R and see what it suggests!
>
{: .challenge}
