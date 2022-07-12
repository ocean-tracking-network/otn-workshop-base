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

R can access files on and save outputs to any folder on your computer. R knows where to look for and save files based on the current working directory. This is one of the first things you should set up: a folder you'd like to contain all your data, scripts and outputs. The working directory path will be different for everyone. For the workshop, we've included the path one of our instructors uses, but you should use your computer's file explorer to find the correct path for your data.


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


setwd('C:/Users/tress_n/2021-04-13-act-workshop/data') #set folder you're going to work in
getwd() #check working directory

#you can also change it in the RStudio interface by navigating in the file browser where your working directory should be
#(if you can't see the folder you want, choose the three horizonal dots on the right side of the Home bar),
#and clicking on the blue gear icon "More", and select "Set As Working Directory".
~~~
{: .language-r}

Before we begin the lesson proper, a note on finding additional help. R Libraries, like those included above, are broad and contain many functions. Though most include documentation that can help if you know what to look for, sometimes more general help is necessary. To that end, RStudio maintains cheatsheets for several of the most popular libraries, which can be found here: [https://www.rstudio.com/resources/cheatsheets/](https://www.rstudio.com/resources/cheatsheets/). As a start, the page includes an RStudio IDE cheatsheet that you may find useful while learning to navigate your workspace. With that in mind, let's start learning R. 

## Intro to R

Like most programming langauges, we can do basic mathematical operations with R. These, along with variable assignment, form the basis of everything for which we will use R.

### Operators

Operators in R include standard mathematical operators (+, -, *, /) as well as an assignment operator, <- (a less-than sign followed by a hyphen). The assignment operator is used to associate a value with a variable name (or, to 'assign' the value a name). This lets us refer to that value later, by the name we've given to it. This may look unfamiliar, but it fulfils the same function as the '=' operator in most other languages.

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
>
> > ## Solution
> >No! You have to re-assign 2.2*weight_kg to the object weight_lb for it to update.
> >
> >The order you run your operations is very important, if you change something you may need to re-run everything!
> >~~~
> >weight_kg <- 100
> >
> >weight_lb #didnt change!
> >
> >weight_lb <- 2.2 * weight_kg #now its updated
> > ~~~
> > {: .language-r}
> {: .solution}
{: .challenge}

### Functions

While we can write code as we have in the section above - line by line, executed one line at a time - it is often more efficient to run multiple lines of code at once. By using functions, we can even compress complex calculations into just one line!

Functions use a single name to refer to underlying blocks of code that execute a specific calculation. To run a function you need two things: the name of the function, which is usually indicative of the function's purpose; and the function's arguments- the variables or values on which the function should execute.

~~~
#functions take "arguments": you have to tell them what to run their script against

ten <- sqrt(weight_kg) #contain calculations wrapped into one command to type.
#Output of the function can be assigned directly to a variable...

round(3.14159) #... but doesn't have to be.
~~~
{: .language-r}

Since there are hundreds of functions and often their functionality can be nuanced, we have several ways to get more information on a given function. First, we can use 'args()', itself a function that takes the name of another function as an argument, which will tell us the required arguments of the function against which we run it.

Second, we can use the '?' operator. Typing a question mark followed by the name of a function will open a Help window in RStudio's bottom-right panel. This will contain the most complete documentation available for the function in question. 

~~~
args(round) #the args() function will show you the required arguments of another function

?round #will show you the full help page for a function, so you can see what it does
~~~
{: .language-r}

> ## Functions Challenge
>
> Can you round the value 3.14159 to two decimal places?
>
> Hint: Using args() on a function can give you a clue.
>
> > ## Solution
> > ~~~
> > round(3.14159, 2) #the round function's second argument is the number of digits you want in the result
> > round(3.14159, digits = 2) #same as above
> > round(digits = 2, x = 3.14159) #when reordered you need to specify
> > ~~~
> > {: .language-r}
> {: .solution}
{: .challenge}

### Vectors and Data Types

While variables can hold a single value, sometimes we want to store multiple values in the same variable name. For this, we can use an R data structure called a 'vector.' Vectors contain one or more variables of the same data type, and can be assigned to a single variable name, as below.

~~~
weight_g <- c(21, 34, 39, 54, 55) #use the combine function to join values into a vector object

length(weight_g) #explore vector
class(weight_g) #a vector can only contain one data type
str(weight_g) #find the structure of your object.
~~~
{: .language-r}

Above, we mentioned 'data type'. This refers to the kind of data represented by a value, or stored by the appropriate variable. Data types include character (words or letters), logical (boolean TRUE or FALSE values), or numeric data. Crucially, vectors can only contain one type of data, and will force all data in the vector to conform to that type (i.e, data in the vector will all be treated as the same data type, regardless of whether or not it was of that type when the vector was created.) We can always check the data type of a variable or vector by using the 'class()' function, which takes the variable name as an argument. 

~~~
#our first vector is numeric.
#other options include: character (words), logical (TRUE or FALSE), integer etc.

animals <- c("mouse", "rat", "dog") #to create a character vector, use quotes

class(weight_g)
class(animals)

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
> > ## Solution
> > R will force all of these to be characters, since the number 4 has quotes around it! 
> > Will always coerce data types following this structure: logical → numeric → character ← logical
> > ~~~
> > class(challenge3)
> > ~~~
> > {: .language-r}
> {: .solution}
{: .challenge}

### Indexing and Subsetting

We can use subsetting to select only a portion of a vector. For this, we use square brackets after the name of a vector. If we supply a single numeric value, as below, we will retrieve only the value from that index of the vector. Note: vectors in R are indexed with 1 representing the first index- other languages use 0 for the start of their array, so if you are coming from a language like Python, this can be disorienting. 

~~~
animals #calling your object will print it out
animals[2] #square brackets = indexing. selects the 2nd value in your vector
~~~
{: .language-r}

We can select a specific value, as above, but we can also select one or more entries based on conditions. By supplying one or more criteria to our indexing syntax, we can retrieve the elements of the array that match that criteria. 

~~~
weight_g > 50 #conditional indexing: selects based on criteria
weight_g[weight_g <=30 | weight_g == 55] #many new operators here!  
                                         #<= less than or equal to; | "or"; == equal to. Also available are >=, greater than or equal to; < and > for less than or greater than (no equals); and & for "and". 
weight_g[weight_g >= 30 & weight_g == 21] #  >=  greater than or equal to, & "and"
                                          # this particular example give 0 results - why?
~~~
{: .language-r}

### Missing Data

In practical data analysis, our data is often incomplete. It is therefore useful to cover some methods of dealing with NA values. NA is R's shorthand for a null value; or a value where there is no data. Certain functions cannot process NA data, and therefore provide arguments that allow NA values to be removed before the function execution.

~~~
heights <- c(2, 4, 4, NA, 6)
mean(heights) #some functions cant handle NAs
mean(heights, na.rm = TRUE) #remove the NAs before calculating
~~~
{: .language-r}

This can be done within an individual function as above, but for our entire analysis we may want to produce a copy of our dataset without the NA values included. Below, we'll explore a few ways to do that.

~~~
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
> > ## Solution
> > ~~~
> > heights_no_na <- heights[!is.na(heights)] 
> > # or
> > heights_no_na <- na.omit(heights)
> > # or
> > heights_no_na <- heights[complete.cases(heights)]
> > ~~~
> > {: .language-r}
> {: .solution}
>
> Question 2: Use the function median() to calculate the median of the heights vector.
>
> > ## Solution
> > ~~~
> > median(heights, na.rm = TRUE)
> > ~~~
> >  {: .language-r}
> {: .solution}
>
> Bonus question: Use R to figure out how many people in the set are taller than 67 inches.
>
> > ## Solution
> > ~~~
> > heights_above_67 <- heights_no_na[heights_no_na > 67]
> > length(heights_above_67)
> > ~~~
> > {: .language-r}
> {: .solution}
{: .challenge}
