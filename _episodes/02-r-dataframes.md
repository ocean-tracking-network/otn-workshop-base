---
title: Starting with Data Frames
teaching: 25
exercises: 10
questions:
    - "How do I import tabular data?"
	- "How do I explore my data set?"
	- "What are some basic data manipulation functions?"
objectives:
    - "Become familiar with dplyr's methods to summarize and manipulate data"
keypoints:
    - "dpylr makes creating complex data summaries easier, using pipes"
---

### Importing from csv

`dplyr` takes advantage of tidyverse pipes and chains of data manipulation to create powerful exploratory summaries

~~~
#imports file into R. paste the filepath to the unzipped file here!
tqcs_matched_2010 <- read_csv("data/tqcs_matched_detections_2010.csv", guess_max = 117172)

#read_csv() is from tidyverse's readr package --> you can also use read.csv() from base R but it created a dataframe (not tibble) so loads slower
#see https://link.medium.com/LtCV6ifpQbb 

#the guess_max argument is helpful when there are many rows of NAs at the top. R will not assign a data type to that columns until it reaches the max guess.
#I chose to use these here because I got the following warning from read_csv()
	# Warning: 82 parsing failures.
	#   row            col           expected actual                                    file
	#117172 bottom_depth   1/0/T/F/TRUE/FALSE   5    'data/tqcs_matched_detections_2010.csv'
	#117172 receiver_depth 1/0/T/F/TRUE/FALSE   4    'data/tqcs_matched_detections_2010.csv'
	#122664 bottom_depth   1/0/T/F/TRUE/FALSE   17.5 'data/tqcs_matched_detections_2010.csv'
	#122664 receiver_depth 1/0/T/F/TRUE/FALSE   16.5 'data/tqcs_matched_detections_2010.csv'
	#162757 bottom_depth   1/0/T/F/TRUE/FALSE   6    'data/tqcs_matched_detections_2010.csv'

~~~
{: .language-r}


### Exploring Detection Extracts

Let's start with a practical example. What can we find out about these matched detections?
~~~
head(tqcs_matched_2010) #first 6 rows
View(tqcs_matched_2010) #can also click on object in Environment window
str(tqcs_matched_2010) #can see the type of each column (vector)
glimpse(tqcs_matched_2010) #similar to str()

summary(tqcs_matched_2010$latitude) #summary() is a base R function that will spit out some quick stats about a vector (column)
#the $ syntax is the way base R selects columns from a data frame

#Challenge 5: 
#1. What is is the class of the station column in tqcs_matched_2010?
#2. How many rows and columns are in the tqcs_matched_2010 dataset?
~~~
{: .language-r}

### Data Manipulation

What is `dplyr` and how can it be used to create summaries for me?
~~~
library(dplyr) #can use tidyverse package dplyr to do exploration on dataframes in a nicer way

# %>% is a "pipe" which allows you to join functions together in sequence. 
#it can be read as "and then". shortcut: ctrl + shift + m

tqcs_matched_2010 %>% dplyr::select(8) #selects column 8

# dplyr::select this syntax is to specify that we want the select function from the dplyr package. 
#often functions are named the same but do diff things

tqcs_matched_2010 %>% slice(1:5) #selects rows 1 to 5 dplyr way

tqcs_matched_2010 %>% distinct(detectedby) %>% nrow #number of arrays that detected my fish in dplyr!
tqcs_matched_2010 %>% distinct(catalognumber) %>% nrow #number of animals that were detected in 2018 (includes release records)

tqcs_matched_2010 %>% filter(catalognumber=="TQCS-1049258-2008-02-14") #filtering in dplyr!
tqcs_matched_2010 %>% filter(monthcollected >= 10) #month is in/after Oct

#get the mean value across a column
tqcs_matched_2010 %>%
  group_by(catalognumber) %>%
  summarise(MeanLat=mean(latitude)) #uses pipes and dplyr functions to find mean latitude for each fish

#Challenge 6: 
#1. find the mean latitude and mean longitude for animal "TQCS-1049258-2008-02-14"
#2. find the min lat/long of each animal for detections occurring in July
~~~
{: .language-r}


### Joining Detection Extracts
Here we will join and filter our detection extracts
~~~
tqcs_matched_2011 <- read_csv("data/tqcs_matched_detections_2011.csv", guess_max = 41880)
tqcs_matched_10_11_full <- rbind(tqcs_matched_2010, tqcs_matched_2011) #join the two files

#release records for animals often appear in >1 year, this will remove the duplicates
tqcs_matched_10_11_full <- tqcs_matched_10_11_full %>% distinct() 

View(tqcs_matched_10_11) #wow this is huge!

tqcs_matched_10_11 <- tqcs_matched_10_11_full %>% slice(1:100000) #subset our example data to help this workshop run smoother!

~~~
{: .language-r}


### Dealing with Datetimes
Datetimes are special formats which are not numbers nor characters.
~~~
library(lubridate) 

tqcs_matched_10_11 %>% mutate(datecollected=ymd_hms(datecollected)) #Tells R to treat this column as a date, not number numbers

#as.POSIXct(tqcs_matched_2010$datecollected) #this is the base R way - if you ever see this function

#lubridate is amazing if you have a dataset with multiple datetime formats / timezone
#the function parse_date_time() can be used to specify multiple date formats if you have a dataset with mixed rows
#the function with_tz() can change timezone. accounts for daylight savings too!

#example code to change timezone:
#My_Data_Set %>% mutate(datetime = ymd_hms(datetime, tz = "America/Nassau")) #change your column to a datetime format, specifying TZ (eastern)
#My_Data_Set %>% mutate(datetime_utc = with_tz(datetime, tzone = "UTC")) #make new column called datetime_utc which is datetime converted to UTC

~~~
{: .language-r}

