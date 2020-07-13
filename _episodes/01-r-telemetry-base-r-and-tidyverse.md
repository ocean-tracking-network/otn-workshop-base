---
title: Base R functions vs. Tidyverse
teaching: 30
exercises: 0
questions:
      - "What are common operators in R?"
      - "What are common data types in R?"
      - "How can I introspect, subset, and plot my data using base R?"
      - "How do I reformat dates as 'strings' into date objects?"
      - "What are the Tidyverse functions that will do the same tasks?"
objectives:
      - "Learn how to perform basic R data manipulation tasks in base R, and using the Tidyverse"
keypoints:
      - "Many of the tasks you will need to do to analyze your data are made easier or more readable via Tidyverse methods."
---

The Tidyverse and its component packages are reimagining how you work with tabular data in R. It includes component libraries and functions for organizing code for readability, cleaning data, and plotting it. While tidyverse is only one of a few competing paradigms for performing these jobs in R, here we will show a few examples of performing tasks in base R and again using Tidy methods.

First, some reminders on how to quickly get help with R functions. We will cover some of these as we go.

### Getting help with Functions
~~~

# Getting Help with Functions/Packages ####
?barplot
args(lm)
?lm
~~~

## Intro to R

Learning about R

### Operators
~~~
3 + 5 #maths! including - , *, /

weight_kg <- 55 #assignment operator! for objects/variables. shortcut: alt + - 

weight_lb <- 2.2 * weight_kg #can assign output to an object. can use objects to do calculations
~~~
{: .language-r}

### Functions
~~~
ten <- sqrt(weight_kg) #contain calculations wrapped into one command to type. 
                       #functions take "arguments": you have to tell them what to run their script against

round(3.14159) #don't have to assign

args(round) #the args() function will show you the required arguments of another function

?round #will show you the full help page for a function, so you can see what it does, 
       #what argument it takes etc.

round(3.14159, 2) #the round function's second argument is the number of digits you want in the result
round(3.14159, digits = 2) #same as above
round(digits = 2, x = 3.14159) #when reordered you need to specify
~~~
{: .language-r}

### Vectors and Data Types
~~~
weight_g <- c(21, 34, 39, 54, 55) #use the combine function to join values into a vector object

length(weight_g) #explore vector
class(weight_g) #a vector can only contain one data type
str(weight_g) #find the structure of your object.
              #our vector is numeric. 
              #other options include: character (words), logical (TRUE or FALSE), integer etc.

animals <- c("mouse", "rat", "dog") #to create a character vector, use quotes

#R will convert (force) all values in a vector to the same data type.
#for this reason: try to keep one data type in each vector
#a data table / data frame is just multiple vectors (columns)
~~~
{: .language-r}

### Subsetting
~~~
animals #calling your object will print it out
animals[2] #square brackets = indexing. selects the 2nd value in your vector

weight_g > 50 #conditional indexing: selects based on criteria
weight_g[weight_g <=30 | weight_g == 55] #many new operators here!  
                                         #<= less than or equal to, | "or", == equal to
weight_g[weight_g >= 30 & weight_g == 21] #  >=  greater than or equal to, & "and" 
                                          # this particular example give 0 results - why?
~~~
{: .language-r}

### Missing Data
~~~
heights <- c(2, 4, 4, NA, 6)
mean(heights) #some functions cant handle NAs
mean(heights, na.rm = TRUE) #remove the NAs before calculating

#other ways to get a dataset without NAs:
heights[!is.na(heights)] #indexes for values where its NOT NA 
                         #! is an operator that reverses the function
na.omit(heights) #omit the NAs
heights[complete.cases(heights)] #select only complete cases
~~~
{: .language-r}

## The Tidyverse and Data Frames

Time to explore tabular data and the Tidyverse library!
Data and code helpfully provided by Dr. Robert Lennox of NORCE, see his Twitter @FisheriesRobert

### Intro - looking at data

~~~
# Tidyverse - provides dplyr, ggplot2, and many other packages that simplify data.frame manipulation in R
library(tidyverse)

# Thanks for the data Dr. Lennox!
load("seaTrout.rda")  # load 1.5m sea trout detections from a dataset in the Norwegian fjords.

# Base R way:
str(seaTrout)
# Tidyverse option:
glimpse(seaTrout)

# Base R way:
head(seaTrout)
# alternate way of calling the same head() function using Tidyverse
seaTrout %>% head

# %>% is a "pipe" which allows you to join functions together in sequence. 
#it can be read as "and then". shortcut: ctrl + shift + m
~~~
{: .language-r}

Challenge: what are some useful arguments you can pass to the head function? (Hint: try running ?head to explore)

### Subsetting
~~~
#recall base R indexing
seaTrout[,c(7)] #selects column 7. need an x and y coordinate
seaTrout %>% dplyr::select(7) 

# dplyr::select this syntax is to specify that we want the select function from the dplyr package. 
#often functions are named the same but do diff things

seaTrout[c(1:5),] #selects rows 1 to 5
seaTrout %>% slice(1:5) #dplyr way

seaTrout_full = seaTrout #make a copy of full dataset
seaTrout <- seaTrout %>% slice(1:100000) #make dataframe smaller, so that it will be easier to work with later
~~~
{: .language-r}


### Summarizing data

Useful summaries and other tools

~~~
nrow(data.frame(unique(seaTrout$Species))) #number of species, in base R
seaTrout %>% distinct(Species) %>% nrow #number of species in dplyr!

seaTrout[which(seaTrout$Species=="Trout"),] #filtering a subset of data (only species = AB)
seaTrout %>% filter(Species=="Trout") #filtering in dplyr!

tapply(seaTrout$lon, seaTrout$tag.ID, mean) #get the mean value across a column, in base R
seaTrout %>%
  group_by(tag.ID) %>%
  summarise(mean=mean(lon)) #uses pipes and dplyr functions to do this!
~~~
{: .language-r}


### Dealing with Dates
While a whole module could be written on this topic, here we'll show just the difference between formatting dates using base R and using lubridate, a wonderful library for managing date formats. This is also the first place we'll start to see some minor speed differences in using Tidy vs. base functions.
~~~

as.POSIXct(seaTrout$DateTime) #Tells R to treat this column as a date, not numbers

library(lubridate) #can use tidyverse package lubridate to work with dates easier
seaTrout %>% mutate(DateTime=ymd_hms(DateTime)) #ta-da!

#lubridate is amazing if you have a dataset with multiple datetime formats / timezones
#the function parse_date_time() can be used to specify multiple date formats
#the function with_tz() can change timezone. accounting for daylight savings too!
~~~
{: .language-r}


### Plotting

We'll do some more complex stuff with ggplot in a minute, but if you have two axes and want to see them on a plot, here are the base R and ggplot ways of getting there quickly.
~~~

plot(seaTrout$lon, seaTrout$lat)  #base R

library(ggplot2) #tidyverse-style plotting, a very customizable plotting package
seaTrout %>%  
  ggplot(aes(lon, lat)) + #aes = the aesthetic. x and y etc.
  geom_point() #geom = the type of plot

~~~
{: .language-r}


Questions:
* What arguments does tapply() take? (Hint: try running args(tapply))
* What method of summarizing do you find more readable?
* In base R, what is c()?

FYI, there is a new dplyr, ggplot and R version out recently! 
see full changes w R version 4.0 here https://cran.r-project.org/doc/manuals/r-devel/NEWS.html
see the full changes to dplyr 1.0 here https://www.tidyverse.org/blog/2020/06/dplyr-1-0-0/ 
see the changes to ggplot2 3.0 here https://www.tidyverse.org/blog/2020/03/ggplot2-3-3-0/
the changes as I recognize them:
1. read.csv(), data.frame(), read.table() no longer have `StringsAsFactors = TRUE` as default. 
      check data types on import. 
      now functions same as the dplyr read_csv() function
2. packages need to be re-installed under R version 4.0+
3. some packages won't work (yet) on R 4.0+