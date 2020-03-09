---
title: Base R functions vs. Tidyverse
teaching: 15
exercises: 0
questions:
      - "How can I introspect, subset, and plot my data using base R?"
      - "How do I reformat dates as 'strings' into date objects?"
      - "What are the Tidyverse functions that will do the same tasks?"
objectives:
      - "Learn how to perform basic R data manipulation tasks in base R, and using the Tidyverse"
keypoints:
      - "Many of the tasks you will need to do to analyze your data are made easier or more readable via Tidyverse methods."
---

The Tidyverse and its component packages are reimagining how you work with tabular data in R. It includes component libraries and functions for organizing code for readability, cleaning data, and plotting it. While tidyverse is only one of a few competing paradigms for performing these jobs in R, here we will show a few examples of performing tasks in base R and again using Tidy methods.

First, some reminders on how to quickly get help with R functions.

### Getting help with Functions
~~~

# Getting Help with Functions/Packages ####
?barplot
args(lm)
?lm
~~~

## The Tidyverse

### Intro - looking at data
OK, let's load the Tidyverse libraries, and then load and explore a working dataset that is included in the example repository.
~~~
# Tidyverse - provides dplyr, ggplot2, and many other packages that simplify data.frame manipulation in R
library(tidyverse)

                      # Data and code helpfully provided by Dr. Robert Lennox of NORCE
load("seaTrout.rda")  # load 1.5m sea trout detections from a dataset in the Norwegian fjords.

# Lots of ways to get a clue about what this new data var is and how it looks. The general format of our exploration will be:

# Base R way:
str(seaTrout)

# Tidyverse option:
glimpse(seaTrout)
~~~
{: .language-r}

You can also call a function to just look at the first few rows, `head()`
~~~
# Base R way:
head(seaTrout)

# alternate way of calling the same head() function using Tidyverse's magrittr:
seaTrout %>% head
~~~
{: .language-r}

Challenge: what are some useful arguments you can pass to the head function?


OK, let's do some more subsetting of our data. What if we want one column? How would we return the first 5 rows?
~~~

# Select one column by number, base and then Tidy
seaTrout[,c(6)]

seaTrout %>% select(6)


# Select the first 5 rows.
seaTrout[c(1:5),]

seaTrout %>% slice(1:5)
~~~
{: .language-r}

Question: what's this c() business all about?

### Summarizing data - finding unique values:

OK, something a little more practical, how would we determine what values are in our Species column? First base, then tidy.

~~~
# basic functions 1.2: how many species do we have?

nrow(data.frame(unique(seaTrout$Species)))

seaTrout %>% distinct(Species) %>% nrow
~~~
{: .language-r}



### Dealing with Dates
While a whole module could be written on this topic, here we'll show just the difference between formatting dates using base R and using lubridate, a wonderful library for managing date formats. This is also the first place we'll start to see some minor speed differences in using Tidy vs. base functions.
~~~

# basic function 1.3: format date times

as.POSIXct(seaTrout$DateTime) # Check if your beverage needs refilling

seaTrout %>% mutate(DateTime=ymd_hms(DateTime))  # Lightning-fast, thanks to Lubridate's ymd_hms(), 'yammed hams'!
                                                 # For datestrings in American, try dmy_hms()
~~~
{: .language-r}

### Filtering data

We'll often want to subset data to evaluate what's happening within a subgroup. Here, let's look at selecting out all the Trout in our data vs. the salmon. Some small speed difference here if you can detect it.

~~~
# basic function 1.4: filtering

seaTrout[which(seaTrout$Species=="Trout"),]

seaTrout %>% filter(Species=="Trout")
~~~
{: .language-r}


### Plotting

We'll do some more complex stuff with ggplot in a minute, but if you have two axes and want to see them on a plot, here are the base R and ggplot ways of getting there quickly.
~~~

# basic function 1.5: plotting

plot(seaTrout$lon, seaTrout$lat)  # check again if beverage is full

seaTrout %>% ggplot(aes(lon, lat))+geom_point() # sometimes plots just take time

~~~
{: .language-r}


### Summarizing Data - applying functions to get summaries

We'll do some more complex stuff with ggplot in a minute, but if you have two axes and want to see them on a plot, here are the base R and ggplot ways of getting there quickly.
~~~
# basic function 1.6: getting data summaries

tapply(seaTrout$lon, seaTrout$tag.ID, mean) # get the mean value across a column

seaTrout %>%
  group_by(tag.ID) %>%
  summarise(mean=mean(lon))   # Can use pipes and newlines to organize this process

~~~
{: .language-r}


Questions:
* What arguments does tapply() take?
* What method of summarizing do you find more readable?
