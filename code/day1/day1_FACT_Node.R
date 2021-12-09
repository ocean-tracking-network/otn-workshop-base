# Intro to R for Telemetry Summaries --------

# Installs and Setup --------
library(tidyverse)# really neat collection of packages! https://www.tidyverse.org/
library(lubridate)
library(readxl)
library(viridis)
library(plotly)
library(ggmap)

setwd('C:/Users/ct991305/Documents/Workshop Material/one true workshop - WIP/FACT_data') #set folder you're going to work in
getwd() #check working directory

# Intro to R --------

## Operators ----

3 + 5 #maths! including - , *, /

weight_kg <- 55 #assignment operator! for objects/variables. shortcut: alt + -
weight_kg

weight_lb <- 2.2 * weight_kg #can assign output to an object. can use objects to do calculations

## Functions ----

#functions take "arguments": you have to tell them what to run their script against

ten <- sqrt(weight_kg) #contain calculations wrapped into one command to type.
#Output of the function can be assigned directly to a variable...

round(3.14159) #... but doesn't have to be.

args(round) #the args() function will show you the required arguments of another function

?round #will show you the full help page for a function, so you can see what it does


## Vectors and Data Types ----
weight_g <- c(21, 34, 39, 54, 55) #use the combine function to join values into a vector object

length(weight_g) #explore vector
class(weight_g) #a vector can only contain one data type
str(weight_g) #find the structure of your object.

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

## Indexing and Subsetting ----

animals #calling your object will print it out
animals[2] #square brackets = indexing. selects the 2nd value in your vector

weight_g > 50 #conditional indexing: selects based on criteria
weight_g[weight_g <=30 | weight_g == 55] #many new operators here!  

# <= less than or equal to; | "or"; == equal to. Also available are >=, greater than or equal to; < and > for less than or greater than (no equals); and & for "and". 

weight_g[weight_g >= 30 & weight_g == 21] #  >=  greater than or equal to, & "and"
# this particular example give 0 results - why?

## Missing Data ----

heights <- c(2, 4, 4, NA, 6)
mean(heights) #some functions cant handle NAs
mean(heights, na.rm = TRUE) #remove the NAs before calculating

heights[!is.na(heights)] #select for values where its NOT NA
#[] square brackets are the base R way to select a subset of data --> called indexing
#! is an operator that reverses the function

na.omit(heights) #omit the NAs

heights[complete.cases(heights)] #select only complete cases

# Dataframes and dplyr --------
## Importing data from CSV ----

#imports file into R. paste the filepath to the unzipped file here!

tqcs_matched_2010 <- read_csv("tqcs_matched_detections_2010.zip", guess_max = 117172) #Import 2010 detections

## Exploring Detection Extracts ----

head(tqcs_matched_2010) #first 6 rows
View(tqcs_matched_2010) #can also click on object in Environment window
str(tqcs_matched_2010) #can see the type of each column (vector)
glimpse(tqcs_matched_2010) #similar to str()

#summary() is a base R function that will spit out some quick stats about a vector (column)
#the $ syntax is the way base R selects columns from a data frame

summary(tqcs_matched_2010$latitude)

## Data Manipulation ----

library(dplyr) #can use tidyverse package dplyr to do exploration on dataframes in a nicer way

# %>% is a "pipe" which allows you to join functions together in sequence.

tqcs_matched_2010 %>% dplyr::select(6) #selects column 6

# Using the above transliteration: "take tqcs_matched_2010 AND THEN select column number 6 from it using the select function in the dplyr library"

tqcs_matched_2010 %>% slice(1:5) #selects rows 1 to 5 in the dplyr way
# Take tqcs_matched_2010 AND THEN slice rows 1 through 5.

#We can also use multiple pipes.
tqcs_matched_2010 %>% 
  distinct(detectedby) %>% nrow #number of arrays that detected my fish in dplyr!
# Take tqcs_matched_2010 AND THEN select only the unique entries in the detectedby column AND THEN count them with nrow.

#We can do the same as above with other columns too.
tqcs_matched_2010 %>% 
  distinct(catalognumber) %>% 
  nrow #number of animals that were detected 
# Take tqcs_matched_2010 AND THEN select only the unique entries in the catalognumber column AND THEN count them with nrow.

#We can use filtering to conditionally select rows as well.
tqcs_matched_2010 %>% filter(catalognumber=="TQCS-1049258-2008-02-14") 
# Take tqcs_matched_2010 AND THEN select only those rows where catalognumber is equal to the above value.

tqcs_matched_2010 %>% filter(monthcollected >= 10) #all dets in/after October of 2016
# Take tqcs_matched_2010 AND THEN select only those rows where monthcollected is greater than or equal to 10. 

#get the mean value across a column using GroupBy and Summarize

tqcs_matched_2010 %>% #Take tqcs_matched_2010, AND THEN...
  group_by(catalognumber) %>%  #Group the data by catalognumber- that is, create a group within the dataframe where each group contains all the rows related to a specific catalognumber. AND THEN...
  summarise(MeanLat=mean(latitude)) #use summarise to add a new column containing the mean latitude of each group. We named this new column "MeanLat" but you could name it anything

## Joining Detection Extracts ----

tqcs_matched_2011 <- read_csv("tqcs_matched_detections_2011.zip", guess_max = 41880) #Import 2011 detections

tqcs_matched_10_11_full <- rbind(tqcs_matched_2010, tqcs_matched_2011) #Now join the two dataframes

#release records for animals often appear in >1 year, this will remove the duplicates
tqcs_matched_10_11_full <- tqcs_matched_10_11_full %>% distinct() # Use distinct to remove duplicates. 

tqcs_matched_10_11 <- tqcs_matched_10_11_full %>% slice(1:100000) # subset our example data to help this workshop run smoother!

## Dealing with Datetimes ----

library(lubridate) #Import our Lubridate library. 

tqcs_matched_10_11 %>% mutate(datecollected=ymd_hms(datecollected)) #Use the lubridate function ymd_hms to change the format of the date.

#as.POSIXct(tqcs_matched_10_11$datecollected) #this is the base R way - if you ever see this function

# Intro to Plotting with ggplot2 ----

## Background ----

#While `ggplot2` function calls can look daunting at first, they follow a single formula, detailed below.


#Anything within <> braces will be replaced in an actual function call. 
#ggplot(data = <DATA>, mapping = aes(<MAPPINGS>)) + <GEOM_FUNCTION>

#<DATA> refers to the data that we'll be plotting. 

#<MAPPINGS> refers to the aesthetic mappings for the data- 
#that is, which columns in the data will be used to determine which attributes of the graph. 
#For example, if you have columns for latitude and longitude, you may want to map these onto the X and Y axes of the graph. 

#<GEOM_FUNCTION> refers to the style of the plot: what type of plot are we going to make.

library(ggplot2)

tqcs_10_11_plot <- ggplot(data = tqcs_matched_10_11, 
                          mapping = aes(x = longitude, y = latitude)) #can assign a base

tqcs_10_11_plot + 
  geom_point(alpha=0.1, 
             colour = "blue") 
#This will layer our chosen geom onto our plot template. 
#alpha is a transparency argument in case points overlap. Try alpha = 0.02 to see how it works!

## Basic Plots ----

#you can combine with dplyr pipes

tqcs_matched_10_11 %>%  
  ggplot(aes(longitude, latitude)) +
  geom_point() #geom = the type of plot


tqcs_matched_10_11 %>%  
  ggplot(aes(longitude, latitude, colour = commonname)) + 
  geom_point()
#anything you specify in the aes() is applied to the actual data points/whole plot,
#anything specified in geom() is applied to that layer only (colour, size...). sometimes you have >1 geom layer so this makes more sense!


# Creating Summary Reports: Importing --------

## Tag Matches ----
View(tqcs_matched_10_11) #already have our Tag matches, from a previous lesson.

# if you do not have the variable created from a previous lesson, you can use the following code to re-create it:

#tqcs_matched_2010 <- read_csv("tqcs_matched_detections_2010.csv", guess_max = 117172) #Import 2010 detections
#tqcs_matched_2011 <- read_csv("tqcs_matched_detections_2011.csv", guess_max = 41880) #Import 2011 detections
#tqcs_matched_10_11_full <- rbind(tqcs_matched_2010, tqcs_matched_2011) #Now join the two dataframes
# release records for animals often appear in >1 year, this will remove the duplicates
#tqcs_matched_10_11_full <- tqcs_matched_10_11_full %>% distinct() # Use distinct to remove duplicates. 
#tqcs_matched_10_11 <- tqcs_matched_10_11_full %>% slice(1:100000) # subset our example data to help this workshop run smoother!

## Array Matches ----
teq_qual_2010 <- read_csv("teq_qualified_detections_2010_ish.csv")
teq_qual_2011 <- read_csv("teq_qualified_detections_2011_ish.csv")
teq_qual_10_11_full <- rbind(teq_qual_2010, teq_qual_2011) 

teq_qual_10_11 <- teq_qual_10_11_full %>% slice(1:100000) #subset our example data for ease of analysis!

## Tagging and Deployment Metadata ----
# Array metadata

teq_deploy <- read.csv("TEQ_Deployments_201001_201201.csv")
View(teq_deploy)

# Tag metadata

tqcs_tag <- read.csv("TQCS_metadata_tagging.csv") 
View(tqcs_tag)

#keep in mind the timezone of the columns


# Creating Summary Reports: Array Operators --------

## Array Map - Static ----
library(ggmap)

#first, what are our columns called?
names(teq_deploy)


#make a basemap for your stations, using the min/max deploy lat and longs as bounding box

base <- get_stamenmap(
  bbox = c(left = min(teq_deploy$DEPLOY_LONG), 
           bottom = min(teq_deploy$DEPLOY_LAT), 
           right = max(teq_deploy$DEPLOY_LONG), 
           top = max(teq_deploy$DEPLOY_LAT)),
  maptype = "terrain-background", 
  crop = FALSE,
  zoom = 8)

#filter for stations you want to plot

teq_deploy_plot <- teq_deploy %>% 
  mutate(deploy_date=ymd_hms(DEPLOY_DATE_TIME....yyyy.mm.ddThh.mm.ss.)) %>% #make a datetime
  mutate(recover_date=ymd_hms(RECOVER_DATE_TIME..yyyy.mm.ddThh.mm.ss.)) %>% #make a datetime
  filter(!is.na(deploy_date)) %>% #no null deploys
  filter(deploy_date > 2010-07-03) %>% #only looking at certain deployments!
  group_by(STATION_NO) %>% 
  summarise(MeanLat=mean(DEPLOY_LAT), MeanLong=mean(DEPLOY_LONG)) #get the mean location per station

# you could choose to plot stations which are within a certain bounding box!
# to do this you would add another filter to the above data, before passing to the map
# ex: add this line after the mutate() clauses:
# filter(latitude >= 0.5 & latitude <= 24.5 & longitude >= 0.6 & longitude <= 34.9)


#add your stations onto your basemap

teq_map <- 
  ggmap(base, extent='panel') +
  ylab("Latitude") +
  xlab("Longitude") +
  geom_point(data = teq_deploy_plot, #filtering for recent deployments
             aes(x = MeanLong,y = MeanLat), #specify the data
             colour = 'blue', shape = 19, size = 2) #lots of aesthetic options here!

#view your receiver map!

teq_map

#save your receiver map into your working directory

ggsave(plot = teq_map, file = "teq_map.tiff", units="in", width=15, height=8)

## Array Map - Interactive ----
library(plotly)

#set your basemap

geo_styling <- list(
  scope = 'usa',
  fitbounds = "locations", visible = TRUE, #fits the bounds to your data!
  showland = TRUE,
  showlakes = TRUE,
  lakecolor = toRGB("blue", alpha = 0.2), #make it transparent
  showcountries = TRUE,
  landcolor = toRGB("gray95"),
  countrycolor = toRGB("gray85")
)

#decide what data you're going to use. Let's use teq_deploy_plot, which we created above for our static map.

teq_map_plotly <- plot_geo(teq_deploy_plot, lat = ~MeanLat, lon = ~MeanLong)  

#add your markers for the interactive map

teq_map_plotly <- teq_map_plotly %>% add_markers(
  text = ~paste(STATION_NO, MeanLat, MeanLong, sep = "<br />"),
  symbol = I("square"), size = I(8), hoverinfo = "text" 
)

#Add layout (title + geo stying)

teq_map_plotly <- teq_map_plotly %>% layout(
  title = 'TEQ Deployments<br />(> 2010-07-03)', geo = geo_styling
)

#View map

teq_map_plotly

## Summary of Animals Detected ----
# How many of each animals did we detect from each collaborator, by species

teq_qual_summary <- teq_qual_10_11 %>% 
  filter(datecollected > '2010-06-01') %>% #select timeframe, stations etc.
  group_by(trackercode, scientificname, tag_contact_pi, tag_contact_poc) %>% 
  summarize(count = n()) %>% 
  select(trackercode, tag_contact_pi, tag_contact_poc, scientificname, count)

#view our summary table

teq_qual_summary #remember, this is just the first 10,000 rows! We subsetted the dataset upon import!

#export our summary table

write_csv(teq_qual_summary, "teq_detection_summary_June2010_to_Dec2011.csv", col_names = TRUE)

## Summary of Detections ----
# number of detections per month/year per station 

teq_det_summary  <- teq_qual_10_11  %>% 
  mutate(datecollected=ymd_hms(datecollected))  %>% 
  group_by(station, year = year(datecollected), month = month(datecollected)) %>% 
  summarize(count =n())

teq_det_summary #remember: this is a subset!

# number of detections per month/year per station & species

teq_anim_summary  <- teq_qual_10_11  %>% 
  mutate(datecollected=ymd_hms(datecollected))  %>% 
  group_by(station, year = year(datecollected), month = month(datecollected), scientificname) %>% 
  summarize(count =n())

teq_anim_summary # remember: this is a subset!


# Create a new data product, det_days, that give you the unique dates that an animal was seen by a station
stationsum <- teq_qual_10_11 %>% 
  group_by(station) %>%
  summarise(num_detections = length(datecollected),
            start = min(datecollected),
            end = max(datecollected),
            species = length(unique(scientificname)),
            uniqueIDs = length(unique(fieldnumber)), 
            det_days=length(unique(as.Date(datecollected))))
View(stationsum)


## Plot of Detections ----

#try with teq_qual_10_11_full if you're feeling bold! takes about 1 min to run on a fast machine

teq_qual_10_11 %>% 
  mutate(datecollected=ymd_hms(datecollected)) %>% #make datetime
  mutate(year_month = floor_date(datecollected, "months")) %>% #round to month
  group_by(year_month) %>% #can group by station, species etc.
  summarize(count =n()) %>% #how many dets per year_month
  ggplot(aes(x = (month(year_month) %>% as.factor()), 
             y = count, 
             fill = (year(year_month) %>% as.factor())
  )
  )+ 
  geom_bar(stat = "identity", position = "dodge2")+ 
  xlab("Month")+
  ylab("Total Detection Count")+
  ggtitle('TEQ Animal Detections by Month')+ #title
  labs(fill = "Year") #legend title

# Creating Summary Reports: Taggers --------
## New Dataframes ----
#optional subsetted dataset to use: detections with releases filtered out!

tqcs_matched_10_11_no_release <- tqcs_matched_10_11 %>% 
  filter(receiver != "release")

#optional full dataset to use: detections with releases filtered out!

tqcs_matched_10_11_full_no_release <- tqcs_matched_10_11_full %>% 
  filter(receiver != "release")

## Detection/Release Map - Static ----
base <- get_stamenmap(
  bbox = c(left = min(tqcs_matched_10_11$longitude),
           bottom = min(tqcs_matched_10_11$latitude), 
           right = max(tqcs_matched_10_11$longitude), 
           top = max(tqcs_matched_10_11$latitude)),
  maptype = "terrain-background", 
  crop = FALSE,
  zoom = 8)


#add your releases and detections onto your basemap

tqcs_map <- 
  ggmap(base, extent='panel') +
  ylab("Latitude") +
  xlab("Longitude") +
  geom_point(data = tqcs_matched_10_11, 
             aes(x = longitude,y = latitude), #specify the data
             colour = 'blue', shape = 19, size = 2) #lots of aesthetic options here!

#view your tagging map!

tqcs_map

## Detection/Release Map - Interactive ----
#set your basemap

geo_styling <- list(
  fitbounds = "locations", visible = TRUE, #fits the bounds to your data!
  showland = TRUE,
  landcolor = toRGB("gray95"),
  subunitcolor = toRGB("gray85"),
  countrycolor = toRGB("gray85")
)

#decide what data you're going to use

tqcs_map_plotly <- plot_geo(tqcs_matched_10_11, lat = ~latitude, lon = ~longitude) 

#add your markers for the interactive map

tqcs_map_plotly <- tqcs_map_plotly %>% add_markers(
  text = ~paste(catalognumber, scientificname, paste("Date detected:", datecollected), 
                paste("Latitude:", latitude), paste("Longitude",longitude), 
                paste("Detected by:", detectedby), paste("Station:", station), 
                paste("Contact:", contact_poc, contact_pi), sep = "<br />"),
  symbol = I("square"), size = I(8), hoverinfo = "text" 
)

#Add layout (title + geo stying)

tqcs_map_plotly <- tqcs_map_plotly %>% layout(
  title = 'TQCS Detections<br />(2010-2011)', geo = geo_styling
)

#View map

tqcs_map_plotly

## Summary of Tagged Animals ----
# summary of animals you've tagged

tqcs_tag_summary <- tqcs_tag %>% 
  mutate(UTC_RELEASE_DATE_TIME = ymd_hms(UTC_RELEASE_DATE_TIME)) %>% 
  #filter(UTC_RELEASE_DATE_TIME > '2019-06-01') %>% #select timeframe, specific animals etc.
  group_by(year = year(UTC_RELEASE_DATE_TIME), COMMON_NAME_E) %>% 
  summarize(count = n(), 
            Meanlength = mean(LENGTH..m., na.rm=TRUE), 
            minlength= min(LENGTH..m., na.rm=TRUE), 
            maxlength = max(LENGTH..m., na.rm=TRUE), 
            MeanWeight = mean(WEIGHT..kg., na.rm = TRUE)) 

#view our summary table

tqcs_tag_summary



## Detection Attributes ----

#Average location of each animal, without release records

tqcs_matched_10_11_no_release %>% 
  group_by(catalognumber) %>% 
  summarize(NumberOfStations = n_distinct(station),
            AvgLat = mean(latitude),
            AvgLong = mean(longitude))

#Now lets try to join our metadata and detection extracts.
#First we need to make a tagname column in the tag metadata, and figure out the enddate of the tag battery

tqcs_tag <- tqcs_tag %>% 
  mutate(enddatetime = (ymd_hms(UTC_RELEASE_DATE_TIME) + days(EST_TAG_LIFE))) %>% #adding enddate
  mutate(tagname = paste(TAG_CODE_SPACE,TAG_ID_CODE, sep = '-')) #adding tagname column

#Now we join by tagname, to the detections without the release information

tag_joined_dets <-  left_join(x = tqcs_matched_10_11_no_release, y = tqcs_tag, by = "tagname")

#make sure the redeployed tags have matched within their deployment period only

tag_joined_dets <- tag_joined_dets %>% 
  filter(datecollected >= UTC_RELEASE_DATE_TIME & datecollected <= enddatetime)

View(tag_joined_dets)

#Lets use this new joined dataframe to make summaries!

# Avg length per location

tqcs_tag_det_summary <- tag_joined_dets %>% 
  group_by(detectedby, station, latitude, longitude)  %>%  
  summarise(AvgSize = mean(LENGTH..m., na.rm=TRUE))

tqcs_tag_det_summary

# count detections per transmitter, per array

tqcs_matched_10_11_no_release %>% 
  group_by(catalognumber, detectedby, commonname) %>% 
  summarize(count = n()) %>% 
  select(catalognumber, commonname, detectedby, count)

# list all receivers each fish was seen on, and a number_of_stations column too

receivers <- tqcs_matched_10_11_no_release %>% 
  group_by(catalognumber) %>% 
  mutate(stations = (list(unique(station)))) %>% #create a column with a list of the stations
  dplyr::select(catalognumber, stations)  %>% #remove excess columns
  distinct_all() %>% #keep only one record of each
  mutate(number_of_stations = sapply(stations, length)) %>% #sapply: applies a function across a List - in this case we are applying length()
  as.data.frame() 

View(receivers)

#Full summary of each animal's track
animal_id_summary <- tqcs_matched_10_11_no_release %>% 
  group_by(catalognumber) %>%
  summarise(dets = length(catalognumber),
            stations = length(unique(station)),
            min = min(datecollected), 
            max = max(datecollected), 
            tracklength = max(datecollected)-min(datecollected))

View(animal_id_summary)

## Plot of Detection Counts ----
#try with tqcs_matched_10_11_full_no_release if you're feeling bold! takes ~30 secs

tqcs_matched_10_11_no_release  %>% 
  mutate(datecollected=ymd_hms(datecollected)) %>% #make datetime
  mutate(year_month = floor_date(datecollected, "months")) %>% #round to month
  group_by(year_month) %>% #can group by station, species etc.
  summarize(count =n()) %>% #how many dets per year_month
  ggplot(aes(x = (month(year_month) %>% as.factor()), 
             y = count, 
             fill = (year(year_month) %>% as.factor())
  )
  )+ 
  geom_bar(stat = "identity", position = "dodge2")+ 
  xlab("Month")+
  ylab("Total Detection Count")+
  ggtitle('TQCS Detections by Month (2010-2011)')+ #title
  labs(fill = "Year") #legend title

# Other Example Plots --------

#Use the color scales in this package to make plots that are pretty, 
#better represent your data, easier to read by those with colorblindness, and print well in grey scale.
library(viridis)

# monthly latitudinal distribution of your animals (works best w >1 species)

tqcs_matched_10_11 %>%
  group_by(m=month(datecollected), catalognumber, scientificname) %>% #make our groups
  summarise(mean=mean(latitude)) %>% #mean lat
  ggplot(aes(m %>% factor, mean, colour=scientificname, fill=scientificname))+ #the data is supplied, but no info on how to show it!
  geom_point(size=3, position="jitter")+   # draw data as points, and use jitter to help see all points instead of superimposition
  #coord_flip()+   #flip x y, not needed here
  scale_colour_manual(values = "blue")+ #change the colour to represent the species better!
  scale_fill_manual(values = "grey")+ 
  geom_boxplot()+ #another layer
  geom_violin(colour="black") #and one more layer


#There are other ways to present a summary of data like this that we might have chosen. 
#geom_density2d() will give us a KDE for our data points and give us some contours across our chosen plot axes.

tqcs_matched_10_11 %>% #doesnt work on the subsetted data, back to original dataset for this one
  group_by(month=month(datecollected), catalognumber, scientificname) %>%
  summarise(meanlat=mean(latitude)) %>%
  ggplot(aes(month, meanlat, colour=scientificname, fill=scientificname))+
  geom_point(size=3, position="jitter")+
  scale_colour_manual(values = "blue")+
  scale_fill_manual(values = "grey")+
  geom_density2d(size=7, lty=1) #this is the only difference from the plot above 

#anything you specify in the aes() is applied to the actual data points/whole plot, 
#anything specified in geom() is applied to that layer only (colour, size...)

# per-individual density contours - lots of plots: called facets!
tqcs_matched_10_11 %>%
  ggplot(aes(longitude, latitude))+
  facet_wrap(~catalognumber)+ #make one plot per individual
  geom_violin()

# an easy abacus plot!

abacus_animals <- 
  ggplot(data = tqcs_matched_10_11_no_release, aes(x = datecollected, y = catalognumber, col = detectedby)) +
  geom_point() +
  ggtitle("Detections by animal") +
  theme(plot.title = element_text(face = "bold", hjust = 0.5)) +
  scale_color_viridis(discrete = TRUE)

abacus_animals

abacus_stations <- 
  ggplot(data = tqcs_matched_10_11_no_release,  aes(x = datecollected, y = station, col = catalognumber)) +
  geom_point() +
  ggtitle("Detections by station") +
  theme(plot.title = element_text(face = "bold", hjust = 0.5)) +
  scale_color_viridis(discrete = TRUE)

abacus_stations 

# track movement using geom_path!!

tqcs_subset <- tqcs_matched_10_11_no_release %>%
  dplyr::filter(catalognumber %in% 
                  c('TQCS-1049282-2008-02-28', 'TQCS-1049281-2008-02-28'))

View(tqcs_subset)

movMap <- 
  ggmap(base, extent = 'panel') + #use the BASE we set up before
  ylab("Latitude") +
  xlab("Longitude") +
  geom_path(data = tqcs_subset, aes(x = longitude, y = latitude, col = commonname)) + #connect the dots with lines
  geom_point(data = tqcs_subset, aes(x = longitude, y = latitude, col = commonname)) + #layer the stations back on
  scale_colour_manual(values = c("red", "blue"), name = "Species")+ #
  facet_wrap(~catalognumber)+
  ggtitle("Inferred Animal Paths")

#to size the dots by number of detections you could do something like: size = (log(length(animal)id))?

movMap
