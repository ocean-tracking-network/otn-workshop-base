---
title: Intro to R
teaching: 30
exercises: 20
questions:
    - "What are common operators in R?"
    - "What are common data types in R?"
    - "What are some base R functions?"
    - "How do I deal with missing data?"
---

First, lets learn about RStudio.

RStudio is divided into 4 "Panes": the Source for your scripts and documents (top-left, in the default layout); your Environment/History (top-right) which shows all the objects in your working space (Environment) and your command history (History); your Files/Plots/Packages/Help/Viewer (bottom-right); and the R Console (bottom-left). The placement of these panes and their content can be customized (see menu, Tools -> Global Options -> Pane Layout).

The R Script in the top pane can be saved and edited, while code typed directly into the Console below will disappear after closing the R session.

R can access files on and save outputs to any folder on your computer. R knows where to look for and save files based on the current working directory. This is one of the first things you should set up: a folder you'd like to contain all your data, scripts and outputs. The working directory path will be different for everyone.


### Setting up R
~~~
# Packages ####
# once you install packages to your computer, you can "check them out" of your packages library each time you need them
# make sure you check the "mask" messages that appear - sometimes packages have functions with the same names!

library(tidyverse)# really neat collection of packages! https://www.tidyverse.org/
library(lubridate)
library(readxl)
library(viridis)
library(plotly)
library(ggmap)


# Working Directory ####

setwd('C:/Users/ct991305/Documents/Workshop Material/2021-04-13-act-workshop/data/') #set folder you're going to work in
getwd() #check working directory

#you can also change it in the RStudio interface by navigating in the file browser where your working directory should be
#(if you can't see the folder you want, choose the three horizonal dots on the right side of the Home bar),
#and clicking on the blue gear icon "More", and select "Set As Working Directory".
~~~
{: .language-r}


## Intro to R

Like most programming langauges, we can do basic mathematical operations with R. These, along with variable assignment, form the basis of everything for which we will use R.

### Operators
~~~
3 + 5 #maths! including - , *, /

weight_kg <- 55 #assignment operator! for objects/variables. shortcut: alt + -
weight_kg

weight_lb <- 2.2 * weight_kg #can assign output to an object. can use objects to do calculations
~~~
{: .language-r}

> ## Variables Challenge
>
> If we change the value of weight_kg to be 100, does the value of weight_lb also change?
> Remember: You can check the contents of an object by typing out its name and running the line in RStudio.
>
{: .challenge}

### Functions
~~~
#functions take "arguments": you have to tell them what to run their script against

ten <- sqrt(weight_kg) #contain calculations wrapped into one command to type.

round(3.14159) #don't have to assign

args(round) #the args() function will show you the required arguments of another function

?round #will show you the full help page for a function, so you can see what it does
~~~
{: .language-r}

> ## Functions Challenge
>
> Can you round the value 3.14159 to two decimal places?
> Hint: Using args() on a function can give you a clue.
>
{: .challenge}

### Vectors and Data Types
~~~
weight_g <- c(21, 34, 39, 54, 55) #use the combine function to join values into a vector object

length(weight_g) #explore vector
class(weight_g) #a vector can only contain one data type
str(weight_g) #find the structure of your object.

#our vector is numeric.
#other options include: character (words), logical (TRUE or FALSE), integer etc.

animals <- c("mouse", "rat", "dog") #to create a character vector, use quotes

# Note:
#R will convert (force) all values in a vector to the same data type.
#for this reason: try to keep one data type in each vector
#a data table / data frame is just multiple vectors (columns)
#this is helpful to remember when setting up your field sheets!
~~~
{: .language-r}

> ## Vectors Challenge
>
> What data type will this vector become?
> ~~~
> challenge3 <- c(1, 2, 3, "4")
> ~~~
> {: .language-r}
> Hint: You can check a vector's type with the class() function.
{: .challenge}

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

heights[!is.na(heights)] #select for values where its NOT NA
#[] square brackets are the base R way to select a subset of data --> called indexing
#! is an operator that reverses the function

na.omit(heights) #omit the NAs

heights[complete.cases(heights)] #select only complete cases
~~~
{: .language-r}

> ## Missing Data Challenge
>
> Question 1: Using the following vector of heighs in inches, create a new vector, called heights_no_na, with the NAs removed.
> ~~~
> heights <- c(63, 69, 60, 65, NA, 68, 61, 70, 61, 59, 64, 69, 63, 63, NA, 72, 65, 64, 70, 63, 65)
> ~~~
> {: .language-r}
>
> Question 2: Use the function median() to calculate the median of the heights vector.
>
> Bonus question: Use R to figure out how many people in the set are taller than 67 inches.
>
{: .challenge}
