---
title: Intro to plotting
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


# Assign plot layout to a variable
tqcs_10_11_plot <- ggplot(data = tqcs_matched_10_11, 
                    mapping = aes(x = latitude, y = longitude)) #can assign a base plot to data, and add the geom() later

# Draw the plot
tqcs_10_11_plot + 
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

tqcs_matched_10_11 %>%  
  ggplot(aes(latitude, longitude)) + 
  geom_point() #geom = the type of plot

tqcs_matched_10_11 %>%  
  ggplot(aes(latitude, longitude, colour = commonname)) + #colour by species!
  geom_point()

#anything you specify in the aes() is applied to the actual data points/whole plot, 
#anything specified in geom() is applied to that layer only (colour, size...)

~~~
{: .language-r}

### Challenge

Try combining with `dplyr` functions in this challenge!
~~~
#Challenge 7: try making a scatterplot showing the lat/long for animal "TQCS-1049258-2008-02-14", coloured by detection array

~~~
{: .language-r}




