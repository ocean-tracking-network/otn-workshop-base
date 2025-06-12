# Intro to R for Telemetry Summaries --------

# Installs and Setup --------
library(tidyverse)# really neat collection of packages! https://www.tidyverse.org/
library(lubridate)
library(readxl)
library(viridis)
library(plotly)
library(ggmap)

setwd('YOUR/PATH/TO/data/act') #set folder you're going to work in
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

#imports file into R. paste the filepath to the file here!

cbcnr_matched_2016 <- read_csv("cbcnr_matched_detections_2016.zip")

## Exploring Detection Extracts ----

head(cbcnr_matched_2016) #first 6 rows
View(cbcnr_matched_2016) #can also click on object in Environment window
str(cbcnr_matched_2016) #can see the type of each column (vector)
glimpse(cbcnr_matched_2016) #similar to str()

#summary() is a base R function that will spit out some quick stats about a vector (column)
#the $ syntax is the way base R selects columns from a data frame

summary(cbcnr_matched_2016$decimalLatitude)

## Data Manipulation ----

library(dplyr) #can use tidyverse package dplyr to do exploration on dataframes in a nicer way

# %>% is a "pipe" which allows you to join functions together in sequence.

cbcnr_matched_2016 %>% dplyr::select(6) #selects column 6
# Using the above transliteration: "take cbcnr_matched_2016 AND THEN select column number 6 from it using the select function in the dplyr library"

cbcnr_matched_2016 %>% slice(1:5) #selects rows 1 to 5 in the dplyr way
# Take cbcnr_matched_2016 AND THEN slice rows 1 through 5.

#We can also use multiple pipes.
cbcnr_matched_2016 %>% 
  distinct(detectedBy) %>% 
  nrow #number of arrays that detected my fish in dplyr!
# Take cbcnr_matched_2016 AND THEN select only the unique entries in the detectedBy column AND THEN count them with nrow.

#We can do the same as above with other columns too.
cbcnr_matched_2016 %>% 
  distinct(catalogNumber) %>% 
  nrow #number of animals that were detected 
# Take cbcnr_matched_2016 AND THEN select only the unique entries in the catalogNumber column AND THEN count them with nrow.

#We can use filtering to conditionally select rows as well.
cbcnr_matched_2016 %>% filter(catalogNumber=="CBCNR-1191602-2014-07-24") 
# Take cbcnr_matched_2016 AND THEN select only those rows where catalogNumber is equal to the above value.

cbcnr_matched_2016 %>% filter(decimalLatitude >= 38)  #all dets in/after October of 2016
# Take cbcnr_matched_2016 AND THEN select only those rows where latitude is greater than or equal to 38. 

#get the mean value across a column using GroupBy and Summarize
cbcnr_matched_2016 %>% #Take cbcnr_matched_2016, AND THEN...
  group_by(catalogNumber) %>%  #Group the data by catalogNumber- that is, create a group within the dataframe where each group contains all the rows related to a specific catalogNumber. AND THEN...
  summarise(MeanLat=mean(decimalLatitude)) #use summarise to add a new column containing the mean decimalLatitude of each group. We named this new column "MeanLat" but you could name it anything

## Joining Detection Extracts ----

cbcnr_matched_2017 <- read_csv("cbcnr_matched_detections_2017.zip") #First, read in our file.

cbcnr_matched_full <- rbind(cbcnr_matched_2016, cbcnr_matched_2017) #Now join the two dataframes

# release records for animals often appear in >1 year, this will remove the duplicates
cbcnr_matched_full <- cbcnr_matched_full %>% distinct() # Use distinct to remove duplicates. 

View(cbcnr_matched_full) 

## Dealing with Datetimes ----

library(lubridate) #Import our Lubridate library. 

cbcnr_matched_full %>% mutate(dateCollectedUTC=ymd_hms(dateCollectedUTC)) #Use the lubridate function ymd_hms to change the format of the date.

#as.POSIXct(cbcnr_matched_full$dateCollectedUTC) #this is the base R way - if you ever see this function

# Intro to Plotting with ggplot2 ----


## Background ----

#While `ggplot2` function calls can look daunting at first, they follow a single formula, detailed below.


#Anything within <> braces will be replaced in an actual function call. 
#ggplot(data = <DATA>, mapping = aes(<MAPPINGS>)) + <GEOM_FUNCTION>
  
#<DATA> refers to the data that we'll be plotting. 

#<MAPPINGS> refers to the aesthetic mappings for the data- 
#that is, which columns in the data will be used to determine which attributes of the graph. 
#For example, if you have columns for decimalLatitude and decimalLongitude, you may want to map these onto the X and Y axes of the graph. 

#<GEOM_FUNCTION> refers to the style of the plot: what type of plot are we going to make.

library(ggplot2)

cbcnr_matched_full_plot <- ggplot(data = cbcnr_matched_full, 
                                   mapping = aes(x = decimalLongitude, y = decimalLatitude)) #can assign a base

cbcnr_matched_full_plot + 
  geom_point(alpha=0.1, 
             colour = "blue") 
#This will layer our chosen geom onto our plot template. 
#alpha is a transparency argument in case points overlap. Try alpha = 0.02 to see how it works!

## Basic Plots ----

#you can combine with dplyr pipes

cbcnr_matched_full %>%  
  ggplot(aes(decimalLongitude, decimalLatitude)) +
  geom_point() #geom = the type of plot


cbcnr_matched_full %>%  
  ggplot(aes(decimalLongitude, decimalLatitude, colour = commonName)) + 
  geom_point()
#anything you specify in the aes() is applied to the actual data points/whole plot,
#anything specified in geom() is applied to that layer only (colour, size...). sometimes you have >1 geom layer so this makes more sense!


# Creating Summary Reports: Importing --------

## Tag Matches ----
View(cbcnr_matched_full) #Check to make sure we already have our tag matches, from a previous episode

# if you do not have the variable created from a previous lesson, you can use the following code to re-create it:

#cbcnr_matched_2016 <- read_csv("cbcnr_matched_detections_2016.zip") #Import 2016 detections
#cbcnr_matched_2017 <- read_csv("cbcnr_matched_detections_2017.zip") # Import 2017 detections
#cbcnr_matched_full <- rbind(cbcnr_matched_2016, cbcnr_matched_2017) #Now join the two dataframes
# release records for animals often appear in >1 year, this will remove the duplicates
#cbcnr_matched_full <- cbcnr_matched_full %>% distinct() # Use distinct to remove duplicates. 

## Array Matches ----

serc1_qual_2016 <- read_csv("serc1_qualified_detections_2016.zip")
serc1_qual_2017 <- read_csv("serc1_qualified_detections_2017.zip", guess_max = 25309)
serc1_qual_16_17_full <- rbind(serc1_qual_2016, serc1_qual_2017) 

## Tagging and Deployment Metadata  ----
#These are saved as XLS/XLSX files, so we need a different library to read them in.
library(readxl)

# Deployment Metadata
serc1_deploy <- read_excel("Deploy_metadata_2016_2017/deploy_sercarray_serc1_2016_2017.xlsx", sheet = "Deployment", skip=3)
View(serc1_deploy)

# Tag metadata
cbcnr_tag <- read_excel("Tag_Metadata/cbcnr_Metadata_cownoseray.xlsx", sheet = "Tag Metadata", skip=4) 
View(cbcnr_tag)

#keep in mind the timezone of the columns

# Creating Summary Reports: Array Operators --------

## Network Receiver Map - Static ----
library(ggmap)


#We'll use the CSV below to tell where our stations and receivers are.
full_receivers <- read.csv('matos_FineToShare_stations_receivers_202104091205.csv')
full_receivers

#what are our columns called?
names(full_receivers)


#make a basemap for all of the stations, using the min/max deploy lat and longs as bounding box

base <- get_stadiamap(
  bbox = c(left = min(full_receivers$stn_long), 
           bottom = min(full_receivers$stn_lat), 
           right = max(full_receivers$stn_long), 
           top = max(full_receivers$stn_lat)),
  maptype = "stamen_terrain_background", 
  crop = FALSE,
  zoom = 6)

#filter for stations you want to plot - this is very customizable

full_receivers_plot <- full_receivers %>% 
  mutate(deploy_date=ymd(deploy_date)) %>% #make a datetime
  mutate(recovery_date=ymd(recovery_date)) %>% #make a datetime
  filter(!is.na(deploy_date)) %>% #no null deploys
  filter(deploy_date > '2011-07-03' & recovery_date < '2018-12-11') %>% #only looking at certain deployments, can add start/end dates here
  group_by(station_name) %>% 
  summarise(MeanLat=mean(stn_lat), MeanLong=mean(stn_long)) #get the mean location per station, in case there is >1 deployment

# you could choose to plot stations which are within a certain bounding box!
# to do this you would add another filter to the above data, before passing to the map
# ex: add this line after the mutate() clauses:
# filter(decimalLatitude <= 0.5 & decimalLatitude >= 24.5 & decimalLongitude <= 0.6 & decimalLongitude >= 34.9)


#add your stations onto your basemap

full_receivers_map <- 
  ggmap(base, extent='panel') + 
  ylab("Latitude") +
  xlab("Longitude") +
  geom_point(data = full_receivers_plot, #filtering for recent deployments
             aes(x = MeanLong, y = MeanLat), #specify the data
             shape = 19, size = 2) #lots of aesthetic options here!

#view your receiver map!
full_receivers_map

#save your receiver map into your working directory

ggsave(plot = full_receivers_map, filename = "act_matos.tiff", units="in", width=15, height=8) 
#can specify file location, file type and dimensions

## Array Map - Static ----
names(serc1_deploy)


base <- get_stadiamap(
  bbox = c(left = min(serc1_deploy$DEPLOY_LONG), 
           bottom = min(serc1_deploy$DEPLOY_LAT), 
           right = max(serc1_deploy$DEPLOY_LONG), 
           top = max(serc1_deploy$DEPLOY_LAT)),
  maptype = "stamen_terrain_background", 
  crop = FALSE,
  zoom = 5)

#filter for stations you want to plot - this is very customizable

serc1_deploy_plot <- serc1_deploy %>% 
  mutate(deploy_date=ymd_hms(`DEPLOY_DATE_TIME   (yyyy-mm-ddThh:mm:ss)`)) %>% #make a datetime
  mutate(recover_date=ymd_hms(`RECOVER_DATE_TIME (yyyy-mm-ddThh:mm:ss)`)) %>% #make a datetime
  filter(!is.na(deploy_date)) %>% #no null deploys
  filter(deploy_date > '2011-07-03' & recover_date < '2018-12-11') %>% #only looking at certain deployments, can add start/end dates here
  group_by(STATION_NO) %>% 
  summarise(MeanLat=mean(DEPLOY_LAT), MeanLong=mean(DEPLOY_LONG)) #get the mean location per station, in case there is >1 deployment


#add your stations onto your basemap

serc1_map <- 
  ggmap(base, extent='panel') + 
  ylab("Latitude") +
  xlab("Longitude") +
  geom_point(data = serc1_deploy_plot, #filtering for recent deployments
             aes(x = MeanLong,y = MeanLat, colour = STATION_NO), #specify the data
             shape = 19, size = 2) #lots of aesthetic options here!

#view your receiver map!
serc1_map

#save your receiver map into your working directory

ggsave(plot = serc1_map, filename = "serc1_map.tiff", units="in", width=15, height=8) 

#can specify location, file type and dimensions

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

#decide what data you're going to use. Let's use serc1_deploy_plot, which we created above for our static map.

serc1_map_plotly <- plot_geo(serc1_deploy_plot, lat = ~MeanLat, lon = ~MeanLong)  

#add your markers for the interactive map

serc1_map_plotly <- serc1_map_plotly %>% add_markers(
  text = ~paste(STATION_NO, MeanLat, MeanLong, sep = "<br />"),
  symbol = I("square"), size = I(8), hoverinfo = "text" 
)

#Add layout (title + geo stying)

serc1_map_plotly <- serc1_map_plotly %>% layout(
  title = 'SERC 1 Deployments<br />(> 2011-07-03)', geo = geo_styling
)

#View map

serc1_map_plotly

## Summary of Animals Detected ----
# How many of each animals did we detect from each collaborator, by species, per station

serc1_qual_summary <- serc1_qual_16_17_full %>% 
  filter(dateCollectedUTC > '2016-06-01') %>% #select timeframe, stations etc.
  group_by(trackerCode, station, contactPI, contactPOC) %>% 
  summarize(count = n()) %>% 
  select(trackerCode, contactPI, contactPOC, station, count)

#view our summary table

serc1_qual_summary 

#export our summary table

write_csv(serc1_qual_summary, "serc1_summary.csv", col_names = TRUE)

## Summary of Detections ----

# number of detections per month/year per station 

serc1_det_summary  <- serc1_qual_16_17_full  %>% 
  mutate(dateCollectedUTC=ymd_hms(dateCollectedUTC))  %>% 
  group_by(station, year = year(dateCollectedUTC), month = month(dateCollectedUTC)) %>% 
  summarize(count =n())

serc1_det_summary 

# Create a new data product, det_days, that give you the unique dates that an animal was seen by a station
stationsum <- serc1_qual_16_17_full %>% 
  group_by(station) %>%
  summarise(num_detections = length(dateCollectedUTC),
            start = min(dateCollectedUTC),
            end = max(dateCollectedUTC),
            uniqueIDs = length(unique(tagName)), 
            det_days=length(unique(as.Date(dateCollectedUTC))))
View(stationsum)


## Plot of Detections ----

serc1_qual_16_17_full %>%  
  mutate(dateCollectedUTC=ymd_hms(dateCollectedUTC)) %>% #make datetime
  mutate(year_month = floor_date(dateCollectedUTC, "months")) %>% #round to month
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
  ggtitle('SERC1 Animal Detections by Month')+ #title
  labs(fill = "Year") #legend title


# Creating Summary Reports: Taggers --------

## New Dataframe ----
#optional dataset to use: detections with releases filtered out!

cbcnr_matched_full_no_release <- cbcnr_matched_full  %>% 
  filter(receiver != "release")

## Detection/Release Map - Static ----
base <- get_stadiamap(
  bbox = c(left = min(cbcnr_matched_full_no_release$decimalLongitude),
           bottom = min(cbcnr_matched_full_no_release$decimalLatitude), 
           right = max(cbcnr_matched_full_no_release$decimalLongitude), 
           top = max(cbcnr_matched_full_no_release$decimalLatitude)),
  maptype = "stamen_terrain_background", 
  crop = FALSE,
  zoom = 5)


#add your releases and detections onto your basemap

cbcnr_map <- 
  ggmap(base, extent='panel') +
  ylab("Latitude") +
  xlab("Longitude") +
  geom_point(data = cbcnr_matched_full_no_release, 
             aes(x = decimalLongitude,y = decimalLatitude), #specify the data
             colour = 'blue', shape = 19, size = 2) #lots of aesthetic options here!

#view your tagging map!

cbcnr_map

## Detection/Release Map - Interactive ----
#set your basemap

geo_styling <- list(
  fitbounds = "locations", visible = TRUE, #fits the bounds to your data!
  showland = TRUE,
  showlakes = TRUE,
  lakecolor = toRGB("blue", alpha = 0.2), #make it transparent
  showcountries = TRUE,
  landcolor = toRGB("gray95"),
  countrycolor = toRGB("gray85")
)

#decide what data you're going to use

detections_map_plotly <- plot_geo(cbcnr_matched_full_no_release, lat = ~decimalLatitude, lon = ~decimalLongitude) 

#add your markers for the interactive map
detections_map_plotly <- detections_map_plotly %>% add_markers(
  text = ~paste(catalogNumber, commonName, paste("Date detected:", dateCollectedUTC), 
                paste("Latitude:", decimalLatitude), paste("Longitude",decimalLongitude), 
                paste("Detected by:", detectedBy), paste("Station:", station), 
                paste("Project:",collectionCode), sep = "<br />"),
  symbol = I("square"), size = I(8), hoverinfo = "text" 
)

#Add layout (title + geo stying)

detections_map_plotly <- detections_map_plotly %>% layout(
  title = 'CBCNR Detections', geo = geo_styling
)

#View map
detections_map_plotly

## Summary of Tagged Animals ----

# summary of animals you've tagged

cbcnr_tag_summary <- cbcnr_tag %>% 
  mutate(UTC_RELEASE_DATE_TIME = ymd_hms(UTC_RELEASE_DATE_TIME)) %>% 
  #filter(UTC_RELEASE_DATE_TIME > '2016-06-01') %>% #select timeframe, specific animals etc.
  group_by(year = year(UTC_RELEASE_DATE_TIME), COMMON_NAME_E) %>% 
  summarize(count = n(), 
            Meanlength = mean(`LENGTH (m)`, na.rm=TRUE), 
            minlength= min(`LENGTH (m)`, na.rm=TRUE), 
            maxlength = max(`LENGTH (m)`, na.rm=TRUE), 
            MeanWeight = mean(`WEIGHT (kg)`, na.rm = TRUE)) 


#view our summary table

cbcnr_tag_summary

## Detection Attributes ----
# Average location of each animal, without release records

cbcnr_matched_full_no_release %>% 
  group_by(catalogNumber) %>% 
  summarize(NumberOfStations = n_distinct(station),
            AvgLat = mean(decimalLatitude),
            AvgLong =mean(decimalLongitude))

#Now lets try to join our metadata and detection extracts.
#First we need to make a tagname column in the tag metadata (to match the Detection Extract), and figure out the enddate of the tag battery.

cbcnr_tag <- cbcnr_tag %>% 
  mutate(enddatetime = (ymd_hms(UTC_RELEASE_DATE_TIME) + days(EST_TAG_LIFE))) %>% #adding enddate
  mutate(tagName = paste(TAG_CODE_SPACE,TAG_ID_CODE, sep = '-')) #adding tagname column

#Now we join by tagname, to the detection dataset (without the release information)

tag_joined_dets <- left_join(x = cbcnr_matched_full_no_release, y = cbcnr_tag, by = "tagName") #join!

#make sure any redeployed tags have matched within their deployment period only

tag_joined_dets <- tag_joined_dets %>% 
  filter(dateCollectedUTC >= UTC_RELEASE_DATE_TIME & dateCollectedUTC <= enddatetime)

View(tag_joined_dets)

#Lets use this new joined dataframe to make summaries!
#Avg length per location

cbcnr_tag_det_summary <- tag_joined_dets %>% 
  group_by(detectedBy, station, decimalLatitude, decimalLongitude)  %>%  
  summarise(AvgSize = mean(`LENGTH (m)`, na.rm=TRUE))

cbcnr_tag_det_summary

#export our summary table as CSV
write_csv(cbcnr_tag_det_summary, "detections_summary.csv", col_names = TRUE)

# count detections per transmitter, per array

cbcnr_matched_full_no_release %>% 
  group_by(catalogNumber, station, detectedBy, commonName) %>% 
  summarize(count = n()) %>% 
  select(catalogNumber, commonName, detectedBy, station, count)

# list all receivers each fish was seen on, and a number_of_receivers column too

receivers <- cbcnr_matched_full_no_release %>% 
  group_by(catalogNumber) %>% 
  mutate(stations = (list(unique(station)))) %>% #create a column with a list of the stations
  dplyr::select(catalogNumber, stations)  %>% #remove excess columns
  distinct_all() %>% #keep only one record of each
  mutate(number_of_stations = sapply(stations, length)) %>% #sapply: applies a function across a List - in this case we are applying length()
  as.data.frame() 

View(receivers)

# number of stations visited, start and end dates, and track length

animal_id_summary <- cbcnr_matched_full_no_release %>% 
  group_by(catalogNumber) %>%
  summarise(dets = length(catalogNumber),
            stations = length(unique(station)),
            min = min(dateCollectedUTC), 
            max = max(dateCollectedUTC), 
            tracklength = max(dateCollectedUTC)-min(dateCollectedUTC))

View(animal_id_summary)

## Plot of Detection Counts ----

cbcnr_matched_full_no_release  %>% 
  mutate(dateCollectedUTC=ymd_hms(dateCollectedUTC)) %>% #make datetime
  mutate(year_month = floor_date(dateCollectedUTC, "months")) %>% #round to month
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
  ggtitle('CBCNR Detections by Month (2016-2017)')+ #title
  labs(fill = "Year") #legend title

# Other Example Plots ----
#Use the color scales in this package to make plots that are pretty, 
#better represent your data, easier to read by those with colorblindness, and print well in grey scale.
library(viridis)

# an easy abacus plot!

abacus_animals <- 
  ggplot(data = cbcnr_matched_full, aes(x = dateCollectedUTC, y = catalogNumber, col = detectedBy)) +
  geom_point() +
  ggtitle("Detections by animal") +
  theme(plot.title = element_text(face = "bold", hjust = 0.5)) +
  scale_color_viridis(discrete = TRUE)

abacus_animals

abacus_stations <- 
  ggplot(data = cbcnr_matched_full,  aes(x = dateCollectedUTC, y = detectedBy, col = catalogNumber)) +
  geom_point() +
  ggtitle("Detections by Array") +
  theme(plot.title = element_text(face = "bold", hjust = 0.5)) +
  scale_color_viridis(discrete = TRUE)

abacus_stations #might be better with just a subset, huh??

# track movement using geom_path!!

cbcnr_subset <- cbcnr_matched_full %>%
  dplyr::filter(catalogNumber %in% c('CBCNR-1191602-2014-07-24', 'CBCNR-1191606-2014-07-24', 
                               'CBCNR-1191612-2014-08-21', 'CBCNR-1218518-2015-09-16'))

View(cbcnr_subset)

movMap <- 
  ggmap(base, extent = 'panel') + #use the BASE we set up before
  ylab("Latitude") +
  xlab("Longitude") +
  geom_path(data = cbcnr_subset, aes(x = decimalLongitude, y = decimalLatitude, col = commonName)) + #connect the dots with lines
  geom_point(data = cbcnr_subset, aes(x = decimalLongitude, y = decimalLatitude, col = commonName)) + #layer the stations back on
  scale_colour_manual(values = c("red", "blue"), name = "Species")+ #
  facet_wrap(~catalogNumber, nrow=2, ncol=2)+
  ggtitle("Inferred Animal Paths")

#to size the dots by number of detections you could do something like: size = (log(length(animal)id))?

movMap

# monthly latitudinal distribution of your animals (works best w >1 species)
cbcnr_matched_full %>%
  group_by(m=month(dateCollectedUTC), catalogNumber, scientificName) %>% #make our groups
  summarise(mean=mean(decimalLatitude)) %>% #mean lat
  ggplot(aes(m %>% factor, mean, colour=scientificName, fill=scientificName))+ #the data is supplied, but no info on how to show it!
  geom_point(size=3, position="jitter")+   # draw data as points, and use jitter to help see all points instead of superimposition
  #coord_flip()+   #flip x y, not needed here
  scale_colour_manual(values = "blue")+ #change the colour to represent the species better!
  scale_fill_manual(values = "grey")+ 
  geom_boxplot()+ #another layer
  geom_violin(colour="black") #and one more layer


#There are other ways to present a summary of data like this that we might have chosen. 
#geom_density2d() will give us a KDE for our data points and give us some contours across our chosen plot axes.

cbcnr_matched_full %>% 
  group_by(month=month(dateCollectedUTC), catalogNumber, scientificName) %>%
  summarise(meanlat=mean(decimalLatitude)) %>%
  ggplot(aes(month, meanlat, colour=scientificName, fill=scientificName))+
  geom_point(size=3, position="jitter")+
  scale_colour_manual(values = "blue")+
  scale_fill_manual(values = "grey")+
  geom_density2d(linewidth=7, lty=1) #this is the only difference from the plot above 

#anything you specify in the aes() is applied to the actual data points/whole plot, 
#anything specified in geom() is applied to that layer only (colour, size...)

# per-individual density contours - lots of plots: called facets!

cbcnr_matched_full %>%
  ggplot(aes(decimalLongitude, decimalLatitude))+
  facet_wrap(~catalogNumber)+ #make one plot per individual
  geom_violin()
#Warnings going on above.
