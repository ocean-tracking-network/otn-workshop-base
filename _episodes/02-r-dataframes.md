---
title: Starting with Data Frames
teaching: 25
exercises: 10
questions:
    - "How do I import tabular data?"
    - "How do I explore my data set?"
    - "What are some basic data manipulation functions?"
---

### Importing from csv

`dplyr` takes advantage of tidyverse pipes and chains of data manipulation to create powerful exploratory summaries.\
If you're unfamiliar with detection extracts formats from OTN-style database nodes, see the documentation [here](https://members.oceantrack.org/data/otn-detection-extract-documentation-matched-to-animals)

~~~
#imports file into R. paste the filepath to the unzipped file here!

proj58_matched_2016 <- read_csv("../ACT_2021_data/ACT Network workshop datasets/proj58_matched_detections_2016.csv")

#read_csv() is from tidyverse's readr package --> you can also use read.csv() from base R but it created a dataframe (not tibble) so loads slower
#see https://link.medium.com/LtCV6ifpQbb

#the guess_max argument is helpful when there are many rows of NAs at the top. R will not assign a data type to that columns until it reaches the max guess.
~~~
{: .language-r}


### Exploring Detection Extracts

Let's start with a practical example. What can we find out about these matched detections?
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

> ## Detection Extracts Challenge
>
> Question 1: What is the class of the station column in proj58_matched_2016?
>
> Question 2: How many rows and columns are in the proj58_matched_2016 dataset?
>
{: .challenge}

### Data Manipulation

What is `dplyr` and how can it be used to create summaries for me?
~~~
library(dplyr) #can use tidyverse package dplyr to do exploration on dataframes in a nicer way

# %>% is a "pipe" which allows you to join functions together in sequence.
#it can be read as "and then". shortcut: ctrl + shift + m

proj58_matched_2016 %>% dplyr::select(6) #selects column 6

# dplyr::select this syntax is to specify that we want the select function from the dplyr package.
#often functions are named the same but do diff things

proj58_matched_2016 %>% slice(1:5) #selects rows 1 to 5 dplyr way

proj58_matched_2016 %>% 
  distinct(detectedby) %>% nrow #number of arrays that detected my fish in dplyr!

proj58_matched_2016 %>% 
  distinct(catalognumber) %>% 
  nrow #number of animals that were detected 

proj58_matched_2016 %>% filter(catalognumber=="PROJ58-1170194-2014-06-18") #filtering in dplyr!

proj58_matched_2016 %>% filter(monthcollected >= 10) #all dets in/after October of 2016

#get the mean value across a column using GroupBy and Summarize

proj58_matched_2016 %>%
  group_by(catalognumber) %>%  #we want to find meanLat for each animal
  summarise(MeanLat=mean(latitude)) #uses pipes and dplyr functions to find mean latitude for each fish. 
                                      #we named this new column "MeanLat" but you could name it anything

~~~
{: .language-r}

> ## Data Manipulation Challenge
>
> Question 1: Find the max lat and max longitude for animal "PROJ58-1170195-2014-05-31".
>
> Question 2: Find the min lat/long of each animal for detections occurring after April 2016.
>
{: .challenge}

## Joining Detection Extracts
Release records for animals often appear in >1 year, this will remove the duplicates
~~~
proj58_matched_2017 <- read_csv("../ACT_2021_data/ACT Network workshop datasets/proj58_matched_detections_2017.csv", guess_max = 41880)
proj58_matched_full <- rbind(proj58_matched_2016, proj58_matched_2017) #join the two files

proj58_matched_full <- proj58_matched_full %>% distinct() 

View(proj58_matched_full) 

proj58_matched_full <- proj58_matched_full %>% slice(1:10000) #subset our example data to help this workshop run smoother!
~~~

### Dealing with Datetimes
Datetimes are special formats which are not numbers nor characters.
~~~
library(lubridate)

proj58_matched_full %>% mutate(datecollected=ymd_hms(datecollected)) #Tells R to treat this column as a date, not number numbers

#as.POSIXct(lamprey_dets$detection_timestamp_utc) #this is the base R way - if you ever see this function

#lubridate is amazing if you have a dataset with multiple datetime formats / timezone
#the function parse_date_time() can be used to specify multiple date formats if you have a dataset with mixed rows
#the function with_tz() can change timezone. accounts for daylight savings too!

#example code to change timezone:
#My_Data_Set %>% mutate(datetime = ymd_hms(datetime, tz = "America/Nassau")) #change your column to a datetime format, specifying TZ (eastern)
#My_Data_Set %>% mutate(datetime_utc = with_tz(datetime, tzone = "UTC")) #make new column called datetime_utc which is datetime converted to UTC

~~~
{: .language-r}
