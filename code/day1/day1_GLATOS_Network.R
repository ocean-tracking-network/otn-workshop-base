# Intro to R for Telemetry Summaries --------

# Installs and Setup --------
library(tidyverse)# really neat collection of packages! https://www.tidyverse.org/
library(lubridate)
library(readxl)
library(viridis)
library(plotly)
library(ggmap)

setwd('YOUR/PATH/TO/data/glatos') #set folder you're going to work in
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

lamprey_dets <- read_csv("inst_extdata_lamprey_detections.csv", guess_max = 3103) 

## Exploring Detection Extracts ----

head(lamprey_dets) #first 6 rows
View(lamprey_dets) #can also click on object in Environment window
str(lamprey_dets) #can see the type of each column (vector)
glimpse(lamprey_dets) #similar to str()

#summary() is a base R function that will spit out some quick stats about a vector (column)
#the $ syntax is the way base R selects columns from a data frame

summary(lamprey_dets$release_latitude)

## Data Manipulation ----

library(dplyr) #can use tidyverse package dplyr to do exploration on dataframes in a nicer way

# %>% is a "pipe" which allows you to join functions together in sequence.

lamprey_dets %>% dplyr::select(6) #selects column 6

# Using the above transliteration: "take lamprey_dets AND THEN select column number 6 from it using the select function in the dplyr library"

lamprey_dets %>% slice(1:5) #selects rows 1 to 5 in the dplyr way
# Take lamprey_dets AND THEN slice rows 1 through 5.

#We can also use multiple pipes.
lamprey_dets %>% 
  distinct(glatos_array) %>% 
  nrow #number of arrays that detected my fish in dplyr!
# Take lamprey_dets AND THEN select only the unique entries in the glatos_array column AND THEN count them with nrow.

#We can do the same as above with other columns too.
lamprey_dets %>% 
  distinct(animal_id) %>% 
  nrow #number of animals that were detected 
# Take lamprey_dets AND THEN select only the unique entries in the animal_id column AND THEN count them with nrow.

#We can use filtering to conditionally select rows as well.
lamprey_dets %>% filter(animal_id=="A69-1601-1363") 
# Take lamprey_dets AND THEN select only those rows where animal_id is equal to the above value.

lamprey_dets %>% filter(detection_timestamp_utc >= '2012-06-01 00:00:00') #all dets in/after October of 2016
# Take lamprey_dets AND THEN select only those rows where monthcollected is greater than or equal to June 1 2012. 

#get the mean value across a column using GroupBy and Summarize

lamprey_dets %>% #Take lamprey_dets, AND THEN...
  group_by(animal_id) %>%  #Group the data by animal_id- that is, create a group within the dataframe where each group contains all the rows related to a specific animal_id. AND THEN...
  summarise(MeanLat=mean(deploy_lat)) #use summarise to add a new column containing the mean latitude of each group. We named this new column "MeanLat" but you could name it anything



## Joining Detection Extracts ----

walleye_dets <- read_csv("inst_extdata_walleye_detections.csv", guess_max = 9595) #Import walleye detections

all_dets <- rbind(lamprey_dets, walleye_dets) #Now join the two dataframes

## Dealing with Datetimes ----

library(lubridate) 

lamprey_dets %>% mutate(detection_timestamp_utc=ymd_hms(detection_timestamp_utc)) #Tells R to treat this column as a date, not number numbers

#as.POSIXct(lamprey_dets$detection_timestamp_utc) #this is the base R way - if you ever see this function

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

lamprey_dets_plot <- ggplot(data = lamprey_dets, 
                                   mapping = aes(x = deploy_long, y = deploy_lat)) #can assign a base

lamprey_dets_plot + 
  geom_point(alpha=0.1, 
             colour = "blue") 
#This will layer our chosen geom onto our plot template. 
#alpha is a transparency argument in case points overlap. Try alpha = 0.02 to see how it works!

## Basic Plots ----

#you can combine with dplyr pipes

all_dets %>%  
  ggplot(aes(deploy_long, deploy_lat)) +
  geom_point() #geom = the type of plot


all_dets %>%  
  ggplot(aes(deploy_long, deploy_lat, colour = common_name_e)) + 
  geom_point()
#anything you specify in the aes() is applied to the actual data points/whole plot,
#anything specified in geom() is applied to that layer only (colour, size...). sometimes you have >1 geom layer so this makes more sense!

# Creating Summary Reports: Importing --------

## Tag Matches ----
View(all_dets) #already have our tag matches

# if you do not have the variable created from a previous lesson, you can use the following code to re-create it:

#lamprey_dets <- read_csv("inst_extdata_lamprey_detections.csv", guess_max = 3103)
#walleye_dets <- read_csv("inst_extdata_walleye_detections.csv", guess_max = 9595) #remember guess_max from prev section!
# lets join these two detection files together!
#all_dets <- rbind(lamprey_dets, walleye_dets)

## GLATOS Workbook ----

library(readxl)

# Deployment Metadata

walleye_deploy <- read_excel('inst_extdata_walleye_workbook.xlsm', sheet = 'Deployment') #pull in deploy sheet
View(walleye_deploy)

walleye_recovery <- read_excel('inst_extdata_walleye_workbook.xlsm', sheet = 'Recovery') #pull in recovery sheet
View(walleye_recovery)

#join the deploy and recovery sheets together

walleye_recovery <- walleye_recovery %>% rename(INS_SERIAL_NO = INS_SERIAL_NUMBER) #first, rename INS_SERIAL_NUMBER so they match between the two dataframes.

walleye_recievers <- merge(walleye_deploy, walleye_recovery,
                           by.x = c("GLATOS_PROJECT", "GLATOS_ARRAY", "STATION_NO",
                                    "CONSECUTIVE_DEPLOY_NO", "INS_SERIAL_NO"), 
                           by.y = c("GLATOS_PROJECT", "GLATOS_ARRAY", "STATION_NO", 
                                    "CONSECUTIVE_DEPLOY_NO", "INS_SERIAL_NO"), 
                           all.x=TRUE, all.y=TRUE) #keep all the info from each, merged using the above columns

View(walleye_recievers)

# Tagging metadata

walleye_tag <- read_excel('inst_extdata_walleye_workbook.xlsm', sheet = 'Tagging')

View(walleye_tag)

#keep in mind the timezone of the columns
#hint: check GLATOS_TIMEZONE column to see if its what you want!

## GLATOS Receiver Stations ----
glatos_receivers <- read_csv("inst_extdata_sample_receivers.csv")
View(glatos_receivers)
# Creating Summary Reports: Array Operators --------

## Network Receiver Map - Static ----
library(ggmap)


#first, what are our columns called?
names(glatos_receivers)


#make a basemap for all of the stations, using the min/max deploy lat and longs as bounding box

base <- get_stamenmap(
  bbox = c(left = min(glatos_receivers$deploy_long), 
           bottom = min(glatos_receivers$deploy_lat), 
           right = max(glatos_receivers$deploy_long), 
           top = max(glatos_receivers$deploy_lat)),
  maptype = "terrain-background", 
  crop = FALSE,
  zoom = 8)

#filter for stations you want to plot - this is very customizable

glatos_deploy_plot <- glatos_receivers %>% 
  mutate(deploy_date=ymd_hms(deploy_date_time)) %>% #make a datetime
  mutate(recover_date=ymd_hms(recover_date_time)) %>% #make a datetime
  filter(!is.na(deploy_date)) %>% #no null deploys
  filter(deploy_date > '2011-07-03' & recover_date < '2018-12-11') %>% #only looking at certain deployments, can add start/end dates here
  group_by(station, glatos_array) %>% 
  summarise(MeanLat=mean(deploy_lat), MeanLong=mean(deploy_long)) #get the mean location per station, in case there is >1 deployment

# you could choose to plot stations which are within a certain bounding box!
#to do this you would add another filter to the above data, before passing to the map
# ex: add this line after the mutate() clauses:
# filter(latitude <= 0.5 & latitude >= 24.5 & longitude <= 0.6 & longitude >= 34.9)


#add your stations onto your basemap

glatos_map <- 
  ggmap(base, extent='panel') + 
  ylab("Latitude") +
  xlab("Longitude") +
  geom_point(data = glatos_deploy_plot, #filtering for recent deployments
             aes(x = MeanLong,y = MeanLat, colour = glatos_array), #specify the data
             shape = 19, size = 2) #lots of aesthetic options here!

#view your receiver map!

glatos_map

#save your receiver map into your working directory

ggsave(plot = glatos_map, filename = "glatos_map.tiff", units="in", width=15, height=8) 
#can specify location, file type and dimensions

## Array Map - Static ----
base <- get_stamenmap(
  bbox = c(left = min(walleye_recievers$DEPLOY_LONG), 
           bottom = min(walleye_recievers$DEPLOY_LAT), 
           right = max(walleye_recievers$DEPLOY_LONG), 
           top = max(walleye_recievers$DEPLOY_LAT)),
  maptype = "terrain-background", 
  crop = FALSE,
  zoom = 8)

#filter for stations you want to plot - this is very customizable

walleye_deploy_plot <- walleye_recievers %>% 
  mutate(deploy_date=ymd_hms(GLATOS_DEPLOY_DATE_TIME)) %>% #make a datetime
  mutate(recover_date=ymd_hms(GLATOS_RECOVER_DATE_TIME)) %>% #make a datetime
  filter(!is.na(deploy_date)) %>% #no null deploys
  filter(deploy_date > '2011-07-03' & is.na(recover_date)) %>% #only looking at certain deployments, can add start/end dates here
  group_by(STATION_NO, GLATOS_ARRAY) %>% 
  summarise(MeanLat=mean(DEPLOY_LAT), MeanLong=mean(DEPLOY_LONG)) #get the mean location per station, in case there is >1 deployment

#add your stations onto your basemap

walleye_deploy_map <- 
  ggmap(base, extent='panel') +
  ylab("Latitude") +
  xlab("Longitude") +
  geom_point(data = walleye_deploy_plot, #filtering for recent deployments
             aes(x = MeanLong,y = MeanLat, colour = GLATOS_ARRAY), #specify the data
             shape = 19, size = 2) #lots of aesthetic options here!


#view your receiver map!

walleye_deploy_map

#save your receiver map into your working directory

ggsave(plot = walleye_deploy_map, filename = "walleye_deploy_map.tiff", units="in", width=15, height=8) 
#can specify location, file type and dimensions

## Network Map - Interactive ----
library(plotly)

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

glatos_map_plotly <- plot_geo(glatos_deploy_plot, lat = ~MeanLat, lon = ~MeanLong)  

#add your markers for the interactive map

glatos_map_plotly <- glatos_map_plotly %>% add_markers(
  text = ~paste(station, MeanLat, MeanLong, sep = "<br />"),
  symbol = I("square"), size = I(8), hoverinfo = "text" 
)

#Add layout (title + geo stying)

glatos_map_plotly <- glatos_map_plotly %>% layout(
  title = 'GLATOS Deployments<br />(> 2011-07-03)', geo = geo_styling
)

#View map

glatos_map_plotly

## Station Performance ----
#How many detections of my tags does each station have?

det_summary  <- all_dets  %>%
  filter(glatos_project_receiver == 'HECST') %>%  #choose to summarize by array, project etc!
  mutate(detection_timestamp_utc=ymd_hms(detection_timestamp_utc))  %>%
  group_by(station, year = year(detection_timestamp_utc), month = month(detection_timestamp_utc)) %>%
  summarize(count =n())

det_summary #number of dets per month/year per station

#How many detections of my tags does each station have? Per species

anim_summary  <- all_dets  %>%
  filter(glatos_project_receiver == 'HECST') %>%  #choose to summarize by array, project etc!
  mutate(detection_timestamp_utc=ymd_hms(detection_timestamp_utc))  %>%
  group_by(station, year = year(detection_timestamp_utc), month = month(detection_timestamp_utc), common_name_e) %>%
  summarize(count =n())

anim_summary #number of dets per month/year per station & species

# Create a new data product, det_days, that give you the unique dates that an animal was seen by a station
stationsum <- all_dets %>% 
  group_by(station) %>%
  summarise(num_detections = length(animal_id),
            start = min(detection_timestamp_utc),
            end = max(detection_timestamp_utc),
            uniqueIDs = length(unique(animal_id)), 
            det_days=length(unique(as.Date(detection_timestamp_utc))))
View(stationsum)


# Creating Summary Reports: Taggers --------

## Detection/Release Map - Static ----
base <- get_stamenmap(
  bbox = c(left = min(all_dets$deploy_long),
           bottom = min(all_dets$deploy_lat), 
           right = max(all_dets$deploy_long), 
           top = max(all_dets$deploy_lat)),
  maptype = "terrain-background", 
  crop = FALSE,
  zoom = 8)


#add your detections onto your basemap
detections_map <- 
  ggmap(base, extent='panel') +
  ylab("Latitude") +
  xlab("Longitude") +
  geom_point(data = all_dets,
             aes(x = deploy_long,y = deploy_lat, colour = common_name_e), #specify the data
             shape = 19, size = 2) #lots of aesthetic options here!

#view your detections map!
detections_map

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

detections_map_plotly <- plot_geo(all_dets, lat = ~deploy_lat, lon = ~deploy_long) 

#add your markers for the interactive map

detections_map_plotly <- detections_map_plotly %>% add_markers(
  text = ~paste(animal_id, common_name_e, paste("Date detected:", detection_timestamp_utc), 
                paste("Latitude:", deploy_lat), paste("Longitude",deploy_long), 
                paste("Detected by:", glatos_array), paste("Station:", station), 
                paste("Project:",glatos_project_receiver), sep = "<br />"),
  symbol = I("square"), size = I(8), hoverinfo = "text" 
)
#Add layout (title + geo stying)

detections_map_plotly <- detections_map_plotly %>% layout(
  title = 'Lamprey and Walleye Detections<br />(2012-2013)', geo = geo_styling
)

#View map

detections_map_plotly

## Summary of Tagged Animals ----
# summary of animals you've tagged
walleye_tag_summary <- walleye_tag %>% 
  mutate(GLATOS_RELEASE_DATE_TIME = ymd_hms(GLATOS_RELEASE_DATE_TIME)) %>% 
  #filter(GLATOS_RELEASE_DATE_TIME > '2012-06-01') %>% #select timeframe, specific animals etc.
  group_by(year = year(GLATOS_RELEASE_DATE_TIME), COMMON_NAME_E) %>% 
  summarize(count = n(), 
            Meanlength = mean(LENGTH, na.rm=TRUE), 
            minlength= min(LENGTH, na.rm=TRUE), 
            maxlength = max(LENGTH, na.rm=TRUE), 
            MeanWeight = mean(WEIGHT, na.rm = TRUE)) 


#view our summary table
walleye_tag_summary

## Detection Attributes ----
#Average location of each animal!

all_dets %>% 
  group_by(animal_id) %>% 
  summarize(NumberOfStations = n_distinct(station),
            AvgLat = mean(deploy_lat),
            AvgLong =mean(deploy_long))


# Avg length per location

all_dets_summary <- all_dets %>% 
  mutate(detection_timestamp_utc = ymd_hms(detection_timestamp_utc)) %>% 
  group_by(glatos_array, station, deploy_lat, deploy_long, common_name_e)  %>%  
  summarise(AvgSize = mean(length, na.rm=TRUE))

all_dets_summary

#export our summary table as CSV
write_csv(all_dets_summary, "detections_summary.csv", col_names = TRUE)

# count detections per transmitter, per array

all_dets %>% 
  group_by(animal_id, glatos_array, common_name_e) %>% 
  summarize(count = n()) %>% 
  select(animal_id, common_name_e, glatos_array, count)

# list all GLATOS arrays each fish was seen on, and a number_of_arrays column too

arrays <- all_dets %>% 
  group_by(animal_id) %>% 
  mutate(arrays =  (list(unique(glatos_array)))) %>% #create a column with a list of the arrays
  dplyr::select(animal_id, arrays)  %>% #remove excess columns
  distinct_all() %>% #keep only one record of each
  mutate(number_of_arrays = sapply(arrays,length)) %>% #sapply: applies a function across a List - in this case we are applying length()
  as.data.frame() 

View(arrays)

#Full summary of each animal's track
animal_id_summary <- all_dets %>% 
  group_by(animal_id) %>%
  summarise(dets = length(animal_id),
            stations = length(unique(station)),
            min = min(detection_timestamp_utc), 
            max = max(detection_timestamp_utc), 
            tracklength = max(detection_timestamp_utc)-min(detection_timestamp_utc))

View(animal_id_summary)


## Plot of Detection Counts ----
all_dets  %>% 
  mutate(detection_timestamp_utc=ymd_hms(detection_timestamp_utc)) %>% #make datetime
  mutate(year_month = floor_date(detection_timestamp_utc, "months")) %>% #round to month
  filter(common_name_e == 'walleye') %>% #can filter for specific stations, dates etc. doesn't have to be species!
  group_by(year_month) %>% #can group by station, species et - doesn't have to be by date
  summarize(count =n()) %>% #how many dets per year_month
  ggplot(aes(x = (month(year_month) %>% as.factor()), 
             y = count, 
             fill = (year(year_month) %>% as.factor())
  )
  )+ 
  geom_bar(stat = "identity", position = "dodge2")+ 
  xlab("Month")+
  ylab("Total Detection Count")+
  ggtitle('Walleye Detections by Month (2012-2013)')+ #title
  labs(fill = "Year") #legend title

# Other Example Plots --------
# an easy abacus plot!

#Use the color scales in this package to make plots that are pretty, 
#better represent your data, easier to read by those with colorblindness, and print well in grey scale.
library(viridis)

abacus_animals <- 
  ggplot(data = all_dets, aes(x = detection_timestamp_utc, y = animal_id, col = glatos_array)) +
  geom_point() +
  ggtitle("Detections by animal") +
  theme(plot.title = element_text(face = "bold", hjust = 0.5)) +
  scale_color_viridis(discrete = TRUE)

abacus_animals

#another way to vizualize

abacus_stations <- 
  ggplot(data = all_dets,  aes(x = detection_timestamp_utc, y = station, col = animal_id)) +
  geom_point() +
  ggtitle("Detections by station") +
  theme(plot.title = element_text(face = "bold", hjust = 0.5)) +
  scale_color_viridis(discrete = TRUE)

abacus_stations

#track movement using geom_path!

movMap <- 
  ggmap(base, extent = 'panel') + #use the BASE we set up before
  ylab("Latitude") +
  xlab("Longitude") +
  geom_path(data = all_dets, aes(x = deploy_long, y = deploy_lat, col = common_name_e)) + #connect the dots with lines
  geom_point(data = all_dets, aes(x = deploy_long, y = deploy_lat, col = common_name_e)) + #layer the stations back on
  scale_colour_manual(values = c("red", "blue"), name = "Species")+ #
  facet_wrap(~animal_id, ncol = 6, nrow=1)+
  ggtitle("Inferred Animal Paths")


movMap


# monthly latitudinal distribution of your animals (works best w >1 species)

all_dets %>%
  group_by(month=month(detection_timestamp_utc), animal_id, common_name_e) %>% #make our groups
  summarise(meanlat=mean(deploy_lat)) %>% #mean lat
  ggplot(aes(month %>% factor, meanlat, colour=common_name_e, fill=common_name_e))+ #the data is supplied, but no info on how to show it!
  geom_point(size=3, position="jitter")+   # draw data as points, and use jitter to help see all points instead of superimposition
  #coord_flip()+   #flip x y, not needed here
  scale_colour_manual(values = c("brown", "green"))+ #change the colour to represent the species better!
  scale_fill_manual(values = c("brown", "green"))+  #colour of the boxplot
  geom_boxplot()+ #another layer
  geom_violin(colour="black") #and one more layer


# per-individual contours - lots of plots: called facets!
all_dets %>%
  ggplot(aes(deploy_long, deploy_lat))+
  facet_wrap(~animal_id)+ #make one plot per individual
  geom_violin()
