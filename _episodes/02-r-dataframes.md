---
title: Starting with Data Frames
teaching: 25
exercises: 10
questions:
    - "How do I import tabular data?"
    - "How do I explore my data set?"
    - "What are some basic data manipulation functions?"
---

###Dataframes and dplyr

In this lesson, we're going to introduce a package called `dplyr`. dplyr takes advantage of an operator called a pipe to create chains of data manipulation that produce powerful exploratory summaries. It also provides a suite of further functionality for manipulating dataframes: tabular sets of data that are common in data analysis. If you've imported the `tidyverse` library, as we did during setup and in the last episode, then congratulations: you already have dplyr (along with a host of other useful packages).

You may not be familiar with dataframes by name, but you may recognize the structure. Dataframes are arranged into rows and columns, not unlike tables in SQL databases. In R, they are represented as vectors of vectors: that is, a vector wherein each index contains another vector. If you are familiar with matrices, or two-dimensional arrays in other languages, the structure of a dataframe will be clear to you. 

However, dataframes are not merely vectors- they are a specific type of object with their own functionality, which we will cover in this lesson. 

We are going to use OTN-style detection extracts for this lesson. If you're unfamiliar with detection extracts formats from OTN-style database nodes, see the documentation [here](https://members.oceantrack.org/data/otn-detection-extract-documentation-matched-to-animals)

###Importing from CSVs

Before we can start analyzing our data, we need to import it into our code space. Fortunately, we have a function for this. `read_csv` is a function from the `readr` package, also included with the tidyverse library. This function can read data from a .csv file into a dataframe. ".csv" is an extension that denotes a Comma-Separated Value file, or a file wherein data is arranged into rows, and entries within rows are delimited by commas. They're common in data analysis.

For the purposes of this lesson, we will only cover read_csv; however, there is another function, `read_excel`, which you can use to import excel files. It's from a different library (`readxl`) and is outside the scope of this lesson, but worth investigating if you need it. 

To import your data from your CSV file, we just need to pass the file path to read_csv, and assign the output to a variable. Note that the file path you give to read_csv will be relative to the working directory you set in the last lesson, so keep that in mind. 

~~~
#imports file into R. paste the filepath to the unzipped file here!

proj58_matched_2016 <- read_csv("proj58_matched_detections_2016.csv")

~~~
{: .language-r}

We can now refer to the variable `proj58_matched_2016` to access, manipulate, and view the data from our CSV. In the next sections, we will explore some of the basic operations you can perform on dataframes. 

### Exploring Detection Extracts

Let's start with a practical example. What can we find out about these matched detections? We'll begin by running the code below, and then give some insight into what each function does. Remember, if you're ever confused about the purpose of a function, you can use '?' followed by the function name (i.e, ?head, ?View) to get more information. 

~~~
head(proj58_matched_2016) #first 6 rows
View(proj58_matched_2016) #can also click on object in Environment window
str(proj58_matched_2016) #can see the type of each column (vector)
glimpse(proj58_matched_2016) #similar to str()

#summary() is a base R function that will spit out some quick stats about a vector (column)
#the $ syntax is the way base R selects columns from a data frame

summary(proj58_matched_2016$latitude)
~~~
{: .language-r}

You may now have an idea of what each of those functions does, but we will briefly explain each here. 

`head` takes the dataframe as a parameter and returns the first 6 rows of the dataframe. This is useful if you want to quickly check that a dataframe imported, or that all the columns are there, or see other such at-a-glance information. Its primary utility is that it is much faster to load and review than the entire dataframe, which may be several tens of thousands of rows long. Note that the related function `tail` will return the **last** six elements. 

If we do want to load the entire dataframe, though, we can use `View`, which will open the dataframe in its own panel, where we can scroll through it as though it were an Excel file. This is useful for seeking out specific information without having to consult the file itself. Note that for large dataframes, this function can take a long time to execute. 

Next are the functions `str` and `glimpse`, which do similar but different things. `str` is short for 'structure' and will print out a lot of information about your dataframe, including the number of rows and columns (called 'observations' and 'variables'), the column names, the first four entries of each column, and each column type as well. `str` can sometimes be a bit overwhelming, so if you want to see a more condensed output, `glimpse` can be useful. It prints less information, but is cleaner and more compact, which can be desirable. 

Finally, we have the `summary` function, which takes a **single column** from a dataframe and produces a summary of its basic statistics. You may have noticed the '$' in the summary call- this is how we index a specific column from a dataframe. In this case, we are referring to the latitude column of our dataframe. 

Using what you now know about summary functions, try to answer the challenge below. 

> ## Detection Extracts Challenge
>
> Question 1: What is the class of the **station** column in proj58_matched_2016, and how many rows and columns are in the proj58_matched_2016 dataset??
> > ## Solution
> > The column is a character, and there are 7,693 rows with 36 columns
> > ~~~
> > str(proj58_matched_2016)
> > # or
> > glimpse(proj58_matched_2016)
> > ~~~
> > {: .language-r}
> {: .solution}
{: .challenge}

### Data Manipulation

Now that we've learned how to import and summarize our data, we can learn how to use `dplyr` to manipulate it. The name 'dplyr' may seem esoteric- the 'd' is short for 'dataframe', and 'plyr' is meant to evoke pliers, and thereby cutting, twisting, and shaping. This is an elegant summation of the `dplyr` library's functionality. 

We are going to introduce a new operator in this section, called the "dplyr pipe". Not to be confused with `|`, which is also called a pipe in some other languages, the dplyr pipe is rendered as `%>%`. A pipe takes the output of the function or contents of the variable on the left and passes them to the function on the right. It is often read as "and then." 

~~~
library(dplyr) #can use tidyverse package dplyr to do exploration on dataframes in a nicer way

# %>% is a "pipe" which allows you to join functions together in sequence.

proj58_matched_2016 %>% dplyr::select(6) #selects column 6

# Using the above transliteration: "take proj58_matched_2016 AND THEN select column number 6 from it using the select function in the dplyr library"

~~~
{: .language-r}

You may have noticed another unfamiliar operator above, the double colon (`::`). This is used to specify the package from which we want to pull a function. Until now, we haven't needed this, but as your code grows and the number of libraries you're using increases, it's likely that multiple functions across several different packages will have the same name (a phenomenon called "overloading"). R has no automatic way of knowing which package contains the function you are referring to, so using double colons lets us specify it explicitly. It's important to be able to do this, since different functions with the same name often do markedly different things. 

Let's explore a few other examples of how we can use dplyr and pipes to manipulate our dataframe. 

~~~
proj58_matched_2016 %>% slice(1:5) #selects rows 1 to 5 in the dplyr way
# Take proj58_matched_2016 AND THEN slice rows 1 through 5.

#We can also use multiple pipes.
proj58_matched_2016 %>% 
  distinct(detectedby) %>% nrow #number of arrays that detected my fish in dplyr!
# Take proj_58_matched_2016 AND THEN select only the unique entries in the detectedby column AND THEN count them with nrow.

#We can do the same as above with other columns too.
proj58_matched_2016 %>% 
  distinct(catalognumber) %>% 
  nrow #number of animals that were detected 
# Take proj_58_matched_2016 AND THEN select only the unique entries in the catalognumber column AND THEN count them with nrow.

#We can use filtering to conditionally select rows as well.
proj58_matched_2016 %>% filter(catalognumber=="PROJ58-1170194-2014-06-18") 
# Take proj58_matched_2016 AND THEN select only those rows where catalognumber is equal to the above value.

proj58_matched_2016 %>% filter(monthcollected >= 10) #all dets in/after October of 2016
# Take proj58_matched_2016 AND THEN select only those rows where monthcollected is greater than or equal to 10. 
~~~
{: .language-r}

These are all ways to extract a specific subset of our data, but `dplyr` can also be used to manipulate dataframes to give you even greater insights. We're now going to use two new functions: `group_by`, which allows us to group our data by the values of a single column, and `summarise` (not to be confused with `summary` above!), which will take the dataframe output of group_by and condense it to fewer rows, trimming out some of the repeated data. Summarise also lets us create new columns based on the data in the dataframe. These functions can be difficult to grasp, so don't forget to use `?group_by` and `?summarise` if you get lost. 

~~~
#get the mean value across a column using GroupBy and Summarize

proj58_matched_2016 %>% #Take proj_58_matched_2016, AND THEN...
  group_by(catalognumber) %>%  #Group the data by catalognumber- that is. create a group within the dataframe where each group contains all the rows related to a specific catalognumber. AND THEN...
  summarise(MeanLat=mean(latitude)) #use summarise to add a new column containing the mean latitude of each group. We named this new column "MeanLat" but you could name it anything

~~~
{: .language-r}

With just a few lines of code, we've created a dataframe that contains each of our catalog numbers and the mean latitude at which those fish were detected. `dplyr`, its wide array of functions, and the powerful pipe operator can let us build out detailed summaries like this one without writing too much code. 

> ## Data Manipulation Challenge
>
> Question 1: Find the max lat and max longitude for animal "PROJ58-1170195-2014-05-31".
> > ## Solution
> > ~~~
> > proj58_matched_2016 %>% 
> >  filter(catalognumber=="PROJ58-1170195-2014-05-31") %>% 
> >  summarise(MaxLat=max(latitude), MaxLong=max(longitude))
> > ~~~
> > {: .language-r}
> {: .solution}
> Question 2: Find the min lat/long of each animal for detections occurring after April 2016.
> > ## Solution
> > ~~~
> > proj58_matched_2016 %>% 
> >   filter(datecollected >= "2016-04-01 00:00:00" ) %>% 
> >   group_by(catalognumber) %>% 
> >   summarise(MinLat=min(latitude), MinLong=min(longitude))
> > ~~~
> > {: .language-r}
> {: .solution}
{: .challenge}

## Joining Detection Extracts
We're now going to briefly touch on a few useful dataframe use cases that aren't directly related to `dplyr`, but with which `dplyr` can help us. 

One function that we'll need to know is `rbind`, a base R function which lets us combine two R objects together. Since release records for animals often appear in multiple years, this functionality will let us merge the dataframes together. We'll also use `distinct`, a `dplyr` function that lets us trim out duplicate data.

~~~
proj58_matched_2017 <- read_csv("proj58_matched_detections_2017.csv", guess_max = 41880) #First, read in our file.

proj58_matched_full <- rbind(proj58_matched_2016, proj58_matched_2017) #Now join the two dataframes

proj58_matched_full <- proj58_matched_full %>% distinct() # Use distinct to remove duplicates. 

View(proj58_matched_full) 

proj58_matched_full <- proj58_matched_full %>% slice(1:10000) #subset our example data to help this workshop run smoother!
~~~
{: .language-r}

You may have noticed that our call to `read_csv` has a second argument this time: guess_max. This is a useful argument when some of our columns begin with a lot of NULL values. When determining what data type to assign to a column, rather than checking every single entry, R will check the first few and make a guess based on that. If the first few values are null, R will get confused and throw an error when it actually finds data further down in the column. `guess_max` lets us tell R exactly how many columns to read before trying to make a guess. This way, we know it will read enough entries in each column to actually find data, which it will prioritize over the NULL values when assigning a type to the column. This parameter isn't always necessary, but it can be vital depending on your dataset. 

### Dealing with Datetimes

Datetime data is in a special format which is neither numeric nor character. It can be tricky to deal with, too, since Excel frequently reformats dates in any file it opens. We also have to concern ourselves with practical matters of time, like time zone and date formatting. Fortunately, the `lubridate` library gives us a whole host of functionality to manage datetime data. 

We'll also use a `dplyr` function called `mutate`, which lets us add new columns or change existing ones, while preserving the existing data in the table. Be careful not to confuse this with its sister function `transmute`, which adds or manipulates columns while *dropping* existing data. If you're ever in doubt as to which is which, remember: `?mutate` and `?transmute` will bring up the help files.

~~~
library(lubridate) #Import our Lubridate library. 

proj58_matched_full %>% mutate(datecollected=ymd_hms(datecollected)) #Use the lubridate function ymd_hms to change the format of the date.

#as.POSIXct(lamprey_dets$detection_timestamp_utc) #this is the base R way - if you ever see this function
~~~
{. :language-r}

We've just used a single function, `ymd_hms`, but with it we've been able to completely reformat the entire datecollected column. `ymd_hms` is short for Year, Month, Day, Hours, Minutes, and Seconds. For example, at time of writing, it's 2021-05-14 2:21:40. Other format functions exist too, like `dmy_hms`, which specifies the day first and year third (i.e, 14-05-2021 2:21:40). Investigate the documentation to find which is right for you. 

There are too many useful lubridate functions to cover in the scope of this lesson. These include `parse_date_time` can be used to read in date data in multiple formats, which is useful if you have a column contianing heterogenous date data; as well as `with_tz`, which lets you make your data sensitive to timezones (including automatic daylight savings time awareness). Dates are a tricky subject, so be sure to investigate `lubridate` to make sure you find the functions you need. 
