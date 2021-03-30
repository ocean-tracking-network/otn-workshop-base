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

lamprey_dets <- read_csv("inst_extdata_lamprey_detections.csv", guess_max = 3102)

#read_csv() is from tidyverse's readr package --> you can also use read.csv() from base R but it created a dataframe (not tibble) so loads slower
#see https://link.medium.com/LtCV6ifpQbb

#the guess_max argument is helpful when there are many rows of NAs at the top. R will not assign a data type to that columns until it reaches the max guess.
#I chose to use this here because I got the following warning from read_csv()
# Warning: 4497 parsing failures.
#row                col           expected     actual                                  file
#3102 sensor_value       1/0/T/F/TRUE/FALSE 66.000     'inst_extdata_lamprey_detections.csv'
#3102 sensor_unit        1/0/T/F/TRUE/FALSE ADC        'inst_extdata_lamprey_detections.csv'
##3102 glatos_caught_date 1/0/T/F/TRUE/FALSE 2012-07-04 'inst_extdata_lamprey_detections.csv'
#3103 sensor_value       1/0/T/F/TRUE/FALSE 62.000     'inst_extdata_lamprey_detections.csv'
#3103 sensor_unit        1/0/T/F/TRUE/FALSE ADC        'inst_extdata_lamprey_detections.csv'

~~~
{: .language-r}


### Exploring Detection Extracts

Let's start with a practical example. What can we find out about these matched detections?
~~~
head(lamprey_dets) #first 6 rows
View(lamprey_dets) #can also click on object in Environment window
str(lamprey_dets) #can see the type of each column (vector)
glimpse(lamprey_dets) #similar to str()

#summary() is a base R function that will spit out some quick stats about a vector (column)
#the $ syntax is the way base R selects columns from a data frame

summary(lamprey_dets$release_latitude)
~~~
{: .language-r}

> ## Detection Extracts Challenge
>
> Question 1: What is the class of the station column in lamprey_dets?
>
> Question 2: How many rows and columns are in the lamprey_dets dataset?
>
{: .challenge}

### Data Manipulation

What is `dplyr` and how can it be used to create summaries for me?
~~~
library(dplyr) #can use tidyverse package dplyr to do exploration on dataframes in a nicer way

# %>% is a "pipe" which allows you to join functions together in sequence.
#it can be read as "and then". shortcut: ctrl + shift + m

lamprey_dets %>% dplyr::select(6) #selects column 6

# dplyr::select this syntax is to specify that we want the select function from the dplyr package.
#often functions are named the same but do diff things

lamprey_dets %>% slice(1:5) #selects rows 1 to 5 dplyr way

lamprey_dets %>%
  distinct(glatos_array) %>%
  nrow #number of arrays that detected my fish in dplyr! first: find the distinct values, then count

lamprey_dets %>%
  distinct(animal_id) %>%
  nrow #number of animals that were detected

lamprey_dets %>% filter(animal_id=="A69-1601-1363") #filtering in dplyr!
lamprey_dets %>% filter(detection_timestamp_utc >= '2012-06-01 00:00:00') #all dets on/after June 1 2012 - conditional filtering!

#get the mean value across a column using GroupBy and Summarize

lamprey_dets %>%
  group_by(animal_id) %>%  #we want to find meanLat for each animal
  summarise(MeanLat=mean(deploy_lat)) #uses pipes and dplyr functions to find mean latitude for each fish.
                                      #we named this new column "MeanLat" but you could name it anything
~~~
{: .language-r}

> ## Data Manipulation Challenge
>
> Question 1: Find the max lat and max long for animal "A69-1601-1363".
>
> Question 2: Find the min lat/long of each animal for detections occurring in July 2012.
>
{: .challenge}

### Dealing with Datetimes
Datetimes are special formats which are not numbers nor characters.
~~~
library(lubridate)

lamprey_dets %>% mutate(detection_timestamp_utc=ymd_hms(detection_timestamp_utc)) #Tells R to treat this column as a date, not number numbers

#as.POSIXct(lamprey_dets$detection_timestamp_utc) #this is the base R way - if you ever see this function

#lubridate is amazing if you have a dataset with multiple datetime formats / timezone
#the function parse_date_time() can be used to specify multiple date formats if you have a dataset with mixed rows
#the function with_tz() can change timezone. accounts for daylight savings too!

#example code to change timezone:
#My_Data_Set %>% mutate(datetime = ymd_hms(datetime, tz = "America/Nassau")) #change your column to a datetime format, specifying TZ (eastern)
#My_Data_Set %>% mutate(datetime_utc = with_tz(datetime, tzone = "UTC")) #make new column called datetime_utc which is datetime converted to UTC

~~~
{: .language-r}
