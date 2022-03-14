# Intro to R for Telemetry Summaries --------

# Prepared by Ocean Tracking Network in Feb 2022
# for MigraMar Network Student Workshop 2022
# contact otndc@dal.ca for questions


# Installs and Setup --------
library(tidyverse)# really neat collection of packages! https://www.tidyverse.org/
library(lubridate)
library(readxl)
library(viridis)
library(plotly)
library(ggmap)

setwd('YOUR/PATH/TO/migramar-student-workshop-2022/') #set folder you're going to work in
getwd() #check working directory

# For a range of cheatsheets that can help with some of the libraries in this lesson, RStudio maintains a repository
# of cheatsheets for popular libraries here: https://www.rstudio.com/resources/cheatsheets/

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

gmr_matched_2018 <- read_csv("data/migramar/gmr_matched_detections_2018.csv")

## Exploring Detection Extracts ----

head(gmr_matched_2018) #first 6 rows
view(gmr_matched_2018) #can also click on object in Environment window
str(gmr_matched_2018) #can see the type of each column (vector)
glimpse(gmr_matched_2018) #similar to str()

#summary() is a base R function that will spit out some quick stats about a vector (column)
#the $ syntax is the way base R selects columns from a data frame

summary(gmr_matched_2018$latitude)

## Data Manipulation ----

library(dplyr) #can use tidyverse package dplyr to do exploration on dataframes in a nicer way

# %>% is a "pipe" which allows you to join functions together in sequence.

gmr_matched_2018 %>% dplyr::select(6) #selects column 6
# Using the above transliteration: "take gmr_matched_2018 AND THEN select column number 6 from it using the select function in the dplyr library"

gmr_matched_2018 %>% slice(1:5) #selects rows 1 to 5 in the dplyr way
# Take gmr_matched_2018 AND THEN slice rows 1 through 5.

#We can also use multiple pipes.
gmr_matched_2018 %>%
  distinct(detectedby) %>%
  nrow #number of arrays that detected my fish in dplyr!
# Take gmr_matched_2018 AND THEN select only the unique entries in the detectedby column AND THEN count them with nrow.

#We can do the same as above with other columns too.
gmr_matched_2018 %>%
  distinct(catalognumber) %>%
  nrow #number of animals that were detected
# Take gmr_matched_2018 AND THEN select only the unique entries in the catalognumber column AND THEN count them with nrow.

#We can use filtering to conditionally select rows as well.
gmr_matched_2018 %>% dplyr::filter(catalognumber=="GMR-25718-2014-01-17")
# Take gmr_matched_2018 AND THEN select only those rows where catalognumber is equal to the above value.

gmr_matched_2018 %>% dplyr::filter(monthcollected >= 10) #all dets in/after October of 2018
# Take gmr_matched_2018 AND THEN select only those rows where monthcollected is greater than or equal to 10.

#get the mean value across a column using GroupBy and Summarize
gmr_matched_2018 %>% #Take gmr_matched_2018, AND THEN...
  group_by(catalognumber) %>%  #Group the data by catalognumber- that is, create a group within the dataframe where each group contains all the rows related to a specific catalognumber. AND THEN...
  summarise(MeanLat=mean(latitude)) #use summarise to add a new column containing the mean latitude of each group. We named this new column "MeanLat" but you could name it anything

## Joining Detection Extracts ----

gmr_matched_2019 <- read_csv("data/migramar/gmr_matched_detections_2019.csv") #First, read in our file.

gmr_matched_18_19 <- rbind(gmr_matched_2018, gmr_matched_2019) #Now join the two dataframes

# release records for animals often appear in >1 year, this will remove the duplicates
gmr_matched_18_19 <- gmr_matched_18_19 %>% distinct() # Use distinct to remove duplicates.

view(gmr_matched_18_19)

## Dealing with Datetimes ----

library(lubridate) #Import our Lubridate library.

gmr_matched_18_19 %>% mutate(datecollected=ymd_hms(datecollected)) #Use the lubridate function ymd_hms to change the format of the date.

#as.POSIXct(gmr_matched_18_19$datecollected) #this is the base R way - if you ever see this function

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

gmr_matched_18_19_plot <- ggplot(data = gmr_matched_18_19,
                                   mapping = aes(x = longitude, y = latitude)) #can assign a base

gmr_matched_18_19_plot +
  geom_point(alpha=0.1,
             colour = "blue")
#This will layer our chosen geom onto our plot template.
#alpha is a transparency argument in case points overlap. Try alpha = 0.02 to see how it works!

## Basic Plots ----

#you can combine with dplyr pipes

gmr_matched_18_19 %>%
  ggplot(aes(longitude, latitude)) +
  geom_point() #geom = the type of plot


gmr_matched_18_19 %>%
  ggplot(aes(longitude, latitude, colour = commonname)) +
  geom_point()
#anything you specify in the aes() is applied to the actual data points/whole plot,
#anything specified in geom() is applied to that layer only (colour, size...). sometimes you have >1 geom layer so this makes more sense!

# For more detailed information on common ggplot features, see the ggplot2 cheatsheet by Clara Granell here:
# https://github.com/claragranell/ggplot2/blob/main/ggplot_theme_system_cheatsheet.pdf

# Creating Summary Reports: Importing --------

## Tag Matches ----
view(gmr_matched_18_19) #Check to make sure we already have our tag matches, from a previous episode

# if you do not have the variable created from a previous lesson, you can use the following code to re-create it:

#gmr_matched_2018 <- read_csv("data/migramar/gmr_matched_detections_2018.csv") #Import 2018 detections
#gmr_matched_2019 <- read_csv("data/migramar/gmr_matched_detections_2019.csv") # Import 2019 detections
#gmr_matched_18_19 <- rbind(gmr_matched_2018, gmr_matched_2019) #Now join the two dataframes
# release records for animals often appear in >1 year, this will remove the duplicates
#gmr_matched_18_19 <- gmr_matched_18_19 %>% distinct() # Use distinct to remove duplicates.

## Array Matches ----
gmr_qual_2018 <- read_csv("data/migramar/gmr_qualified_detections_2018.csv")
gmr_qual_2019 <- read_csv("data/migramar/gmr_qualified_detections_2019.csv")
gmr_qual_18_19 <- rbind(gmr_qual_2018, gmr_qual_2019)


## Tagging and Deployment Metadata  ----
#These are saved as XLS/XLSX files, so we need a different library to read them in.
library(readxl)

# Deployment Metadata
gmr_deploy <- read_excel("data/migramar/gmr-deployment-short-form.xls", sheet = "Deployment")
view(gmr_deploy)

# Tag metadata
gmr_tag <- read_excel("data/migramar/gmr_tagging_metadata.xls", sheet = "Tag Metadata")
view(gmr_tag)

#keep in mind the timezone of the columns

# Creating Summary Reports: Array Operators --------

library(ggmap)

## Array Map - Static ----
names(gmr_deploy)


base <- get_stamenmap(
  bbox = c(left = min(gmr_deploy$DEPLOY_LONG),
           bottom = min(gmr_deploy$DEPLOY_LAT),
           right = max(gmr_deploy$DEPLOY_LONG),
           top = max(gmr_deploy$DEPLOY_LAT)),
  maptype = "terrain",
  crop = FALSE,
  zoom = 12)


#filter for stations you want to plot - this is very customizable

gmr_deploy_plot <- gmr_deploy %>%
  dplyr::mutate(deploy_date=ymd_hms(`DEPLOY_DATE_TIME   (yyyy-mm-ddThh:mm:ss)`)) %>% #make a datetime
  dplyr::mutate(recover_date=ymd_hms(`RECOVER_DATE_TIME (yyyy-mm-ddThh:mm:ss)`)) %>% #make a datetime
  dplyr::filter(!is.na(deploy_date)) %>% #no null deploys
  dplyr::filter(deploy_date > '2017-07-03') %>% #only looking at certain deployments, can add start/end dates here
  dplyr::group_by(STATION_NO) %>%
  dplyr::summarise(MeanLat=mean(DEPLOY_LAT), MeanLong=mean(DEPLOY_LONG)) #get the mean location per station, in case there is >1 deployment


#add your stations onto your basemap

gmr_map <-
  ggmap(base) +
  ylab("Latitude") +
  xlab("Longitude") +
  geom_point(data = gmr_deploy_plot, #filtering for recent deployments
             aes(x = MeanLong,y = MeanLat, colour = STATION_NO), #specify the data
             shape = 19, size = 2, alpha = 1) #lots of aesthetic options here!

#view your receiver map!
gmr_map

#save your receiver map into your working directory

ggsave(plot = gmr_map, filename = "gmr_map.tiff", units="in", width=8, height=15)

#can specify location, file type and dimensions

## Array Map - Interactive ----
library(plotly)

#set your basemap

geo_styling <- list(
  scope = 'galapagos',
  #fitbounds = "locations", visible = TRUE, #fits the bounds to your data!
  showland = TRUE,
  showlakes = TRUE,
  lakecolor = toRGB("blue", alpha = 0.2), #make it transparent
  showcountries = TRUE,
  landcolor = toRGB("gray95"),
  countrycolor = toRGB("gray85"),
  lonaxis = list(
    showgrid = TRUE,
    range = c(-92.5, -90)),
  lataxis = list(
    showgrid = TRUE,
    range = c(0, 2)),
  resolution = 50
)

#decide what data you're going to use. Let's use gmr_deploy_plot, which we created above for our static map.

gmr_map_plotly <- plot_geo(gmr_deploy_plot, lat = ~MeanLat, lon = ~MeanLong)

#add your markers for the interactive map

gmr_map_plotly <- gmr_map_plotly %>% add_markers(
  text = ~paste(STATION_NO, MeanLat, MeanLong, sep = "<br />"),
  symbol = I("square"), size = I(8), hoverinfo = "text"
)

#Add layout (title + geo stying)

gmr_map_plotly <- gmr_map_plotly %>% layout(
  title = 'GMR Deployments<br />(> 2017-07-03)', geo = geo_styling)

#view map

gmr_map_plotly

## Summary of Animals Detected ----
# How many of each animals did we detect from each collaborator, per station
library(dplyr) #to ensure no functions are masked by plotly

gmr_qual_summary <- gmr_qual_18_19 %>%
  dplyr::filter(datecollected > '2018-06-01') %>% #select timeframe, stations etc.
  group_by(trackercode, station, tag_contact_pi, tag_contact_poc) %>%
  summarize(count = n()) %>%
  dplyr::select(trackercode, tag_contact_pi, tag_contact_poc, station, count)

#view our summary table

gmr_qual_summary #reminder: this is filtered for certain dates!

#export our summary table

write_csv(gmr_qual_summary, "gmr_array_summary.csv", col_names = TRUE)

## Summary of Detections ----

# number of detections per month/year per station

gmr_det_summary  <- gmr_qual_18_19  %>%
  mutate(datecollected=ymd_hms(datecollected))  %>%
  group_by(station, year = year(datecollected), month = month(datecollected)) %>%
  summarize(count =n())

gmr_det_summary

# Create a new data product, det_days, that give you the unique dates that an animal was seen by a station
stationsum <- gmr_qual_18_19 %>%
  group_by(station) %>%
  summarise(num_detections = length(datecollected),
            start = min(datecollected),
            end = max(datecollected),
            uniqueIDs = length(unique(fieldnumber)),
            det_days=length(unique(as.Date(datecollected))))
view(stationsum)


## Plot of Detections ----

gmr_qual_18_19 %>%
  mutate(datecollected=ymd_hms(datecollected)) %>% #make datetime
  mutate(year_month = floor_date(datecollected, "months")) %>% #round to month
  group_by(year_month) %>% #can group by station, collaborator etc.
  summarize(count =n()) %>% #how many dets per year_month
  ggplot(aes(x = (month(year_month) %>% as.factor()),
             y = count,
             fill = (year(year_month) %>% as.factor())
  )
  )+
  geom_bar(stat = "identity", position = "dodge2")+
  xlab("Month")+
  ylab("Total Detection Count")+
  ggtitle('GMR Collected Detections by Month')+ #title
  labs(fill = "Year") #legend title


# Creating Summary Reports: Taggers --------

## New Dataframe ----
#optional dataset to use: detections with releases filtered out!

gmr_matched_18_19_no_release <- gmr_matched_18_19  %>%
  dplyr::filter(receiver != "release")

## Detection Map - Static ----
base <- get_stamenmap(
  bbox = c(left = min(gmr_matched_18_19_no_release$longitude),
           bottom = min(gmr_matched_18_19_no_release$latitude),
           right = max(gmr_matched_18_19_no_release$longitude),
           top = max(gmr_matched_18_19_no_release$latitude)),
  maptype = "terrain",
  crop = FALSE,
  zoom = 12)


#add your releases and detections onto your basemap

gmr_tag_map <-
  ggmap(base, extent='panel') +
  ylab("Latitude") +
  xlab("Longitude") +
  geom_point(data = gmr_matched_18_19_no_release,
             aes(x = longitude,y = latitude), #specify the data
             colour = 'blue', shape = 19, size = 2) #lots of aesthetic options here!

#view your tagging map!

gmr_tag_map

## Detection Map - Interactive ----
#set your basemap

geo_styling <- list(
  scope = 'galapagos',
  #fitbounds = "locations", visible = TRUE, #fits the bounds to your data!
  showland = TRUE,
  showlakes = TRUE,
  lakecolor = toRGB("blue", alpha = 0.2), #make it transparent
  showcountries = TRUE,
  landcolor = toRGB("gray95"),
  countrycolor = toRGB("gray85"),
  lonaxis = list(
    showgrid = TRUE,
    range = c(-92.5, -90)),
  lataxis = list(
    showgrid = TRUE,
    range = c(0, 2)),
  resolution = 50
)

#decide what data you're going to use

detections_map_plotly <- plot_geo(gmr_matched_18_19_no_release, lat = ~latitude, lon = ~longitude)

#add your markers for the interactive map
detections_map_plotly <- detections_map_plotly %>% add_markers(
  text = ~paste(catalognumber, commonname, paste("Date detected:", datecollected),
                paste("Latitude:", latitude), paste("Longitude",longitude),
                paste("Detected by:", detectedby), paste("Station:", station),
                paste("Project:",collectioncode), sep = "<br />"),
  symbol = I("square"), size = I(8), hoverinfo = "text"
)

#Add layout (title + geo stying)

detections_map_plotly <- detections_map_plotly %>% layout(
  title = 'GMR Tagged Animal Detections', geo = geo_styling
)

#view map
detections_map_plotly

## Summary of Tagged Animals ----

# summary of animals you've tagged

gmr_tag_summary <- gmr_tag %>%
  mutate(UTC_RELEASE_DATE_TIME = ymd_hms(UTC_RELEASE_DATE_TIME)) %>%
  #dplyr::filter(UTC_RELEASE_DATE_TIME > '2018-06-01') %>% #select timeframe, specific animals etc.
  group_by(year = year(UTC_RELEASE_DATE_TIME), COMMON_NAME_E) %>%
  summarize(count = n(),
            Meanlength = mean(`LENGTH (m)`, na.rm=TRUE),
            minlength= min(`LENGTH (m)`, na.rm=TRUE),
            maxlength = max(`LENGTH (m)`, na.rm=TRUE),
            MeanWeight = mean(`WEIGHT (kg)`, na.rm = TRUE))


#view our summary table

gmr_tag_summary

## Detection Attributes ----
# Average location of each animal, without release records

gmr_matched_18_19_no_release %>%
  group_by(catalognumber) %>%
  summarize(NumberOfStations = n_distinct(station),
            AvgLat = mean(latitude),
            AvgLong =mean(longitude))

#Now lets try to join our metadata and detection extracts.
#First we need to make a tagname column in the tag metadata (to match the Detection Extract), and figure out the enddate of the tag battery.

gmr_tag <- gmr_tag %>%
  mutate(enddatetime = (ymd_hms(UTC_RELEASE_DATE_TIME) + days(EST_TAG_LIFE))) %>% #adding enddate
  mutate(tagname = paste(TAG_CODE_SPACE,TAG_ID_CODE, sep = '-')) #adding tagname column

#Now we join by tagname, to the detection dataset (without the release information)

tag_joined_dets <- left_join(x = gmr_matched_18_19_no_release, y = gmr_tag, by = "tagname") #join!

#make sure any redeployed tags have matched within their deployment period only

tag_joined_dets <- tag_joined_dets %>%
  dplyr::filter(datecollected >= UTC_RELEASE_DATE_TIME & datecollected <= enddatetime)

view(tag_joined_dets)

#Lets use this new joined dataframe to make summaries!
#Avg length per location

gmr_tag_det_summary <- tag_joined_dets %>%
  group_by(commonname, detectedby, station, latitude, longitude)  %>%
  summarise(AvgSize = mean(`LENGTH (m)`, na.rm=TRUE))

gmr_tag_det_summary

#export our summary table as CSV
write_csv(gmr_tag_det_summary, "detections_summary.csv", col_names = TRUE)

# count detections per transmitter, per station

gmr_matched_18_19_no_release %>%
  group_by(catalognumber, station, detectedby, commonname) %>%
  summarize(count = n()) %>%
  dplyr::select(catalognumber, commonname, detectedby, station, count)

# list all receivers each fish was seen on, and a number_of_receivers column too

receivers <- gmr_matched_18_19_no_release %>%
  group_by(catalognumber) %>%
  mutate(stations = (list(unique(station)))) %>% #create a column with a list of the stations
  dplyr::select(catalognumber, stations)  %>% #remove excess columns
  distinct_all() %>% #keep only one record of each
  mutate(number_of_stations = sapply(stations, length)) %>% #sapply: applies a function across a List - in this case we are applying length()
  as.data.frame()

view(receivers)

animal_id_summary <- gmr_matched_18_19_no_release %>%
  group_by(catalognumber) %>%
  summarise(dets = length(catalognumber),
            stations = length(unique(station)),
            min = min(datecollected),
            max = max(datecollected),
            tracklength = max(datecollected)-min(datecollected))

view(animal_id_summary)

## Plot of Detection Counts ----

gmr_matched_18_19_no_release  %>%
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
  ggtitle('GMR Tagged Animal Detections by Month (2018-2019)')+ #title
  labs(fill = "Year") #legend title

# Other Example Plots ----
#Use the color scales in this package to make plots that are pretty,
#better represent your data, easier to read by those with colorblindness, and print well in grey scale.
library(viridis)

# an easy abacus plot!

abacus_animals <-
  ggplot(data = gmr_matched_18_19_no_release, aes(x = datecollected, y = catalognumber, col = station)) +
  geom_point() +
  ggtitle("Detections by animal") +
  theme(plot.title = element_text(face = "bold", hjust = 0.5)) +
  scale_color_viridis(discrete = TRUE)

abacus_animals

abacus_stations <-
  ggplot(data = gmr_matched_18_19_no_release,  aes(x = datecollected, y = station, col = catalognumber)) +
  geom_point() +
  ggtitle("Detections by Array") +
  theme(plot.title = element_text(face = "bold", hjust = 0.5)) +
  scale_color_viridis(discrete = TRUE)

abacus_stations

# track movement using geom_path!!

movMap <-
  ggmap(base, extent = 'panel') + #use the BASE we set up before
  ylab("Latitude") +
  xlab("Longitude") +
  geom_path(data = gmr_matched_18_19_no_release, aes(x = longitude, y = latitude, col = commonname)) + #connect the dots with lines
  geom_point(data = gmr_matched_18_19_no_release, aes(x = longitude, y = latitude, col = commonname)) + #layer the stations back on
  scale_colour_manual(values = c("red", "blue"), name = "Species")+ #
  facet_wrap(~catalognumber)+
  ggtitle("Inferred Animal Paths")

#to size the dots by number of detections you could do something like: size = (log(length(animal)id))?

movMap


# monthly latitudinal distribution of your animals (works best w >1 species)
gmr_matched_18_19_no_release %>%
  group_by(month=month(datecollected), catalognumber, scientificname) %>% #make our groups
  summarise(meanLat=mean(latitude)) %>% #mean lat
  ggplot(aes(month %>% factor, meanLat, colour=scientificname, fill=scientificname))+ #the data is supplied, but no info on how to show it!
  geom_point(size=3, alpha = 0.5, position = "jitter")+   # draw data as points, and use jitter to help see all points instead of superimposition
  geom_boxplot()

#anything you specify in the aes() is applied to the actual data points/whole plot,
#anything specified in geom() is applied to that layer only (colour, size...)

# per-individual density contours - lots of plots: called facets!

gmr_matched_18_19_no_release %>%
  ggplot(aes(longitude, latitude))+
  facet_wrap(~catalognumber)+ #make one plot per individual
  geom_violin()
