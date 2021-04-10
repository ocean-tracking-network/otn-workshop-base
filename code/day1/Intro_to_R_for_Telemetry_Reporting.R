# Intro to R for Telemetry Summaries ---------------------------------
# GLATOS workshop 2021-03-30
# Instructors: Bruce Delo and Caitlin Bate

#install.packages("readxl")
#install.packages("viridis")
#install.packages("lubridate")
#install.packages("ggmap")
#install.packages("plotly")
#install.packages("tidyverse")  

library(tidyverse) # really neat collection of packages! https://www.tidyverse.org/

#make sure to read all "mask" messages

setwd('/Users/bruce/Work/2021-04-13-act-workshop') #set folder you're going to work in
getwd() #check working directory

#Everyone check to make sure all the files in the /data folder are UNZIPPED

## Operators ---------------------------------

3 + 5 #maths! including - , *, /

weight_kg <- 55 #assignment operator! for objects/variables. shortcut: alt + - 
weight_kg

weight_lb <- 2.2 * weight_kg #can assign output to an object. can use objects to do calculations

# Challenge 1:
# if we change the value of weight_kg to be 100, does the value of weight_lb also change automatically?
# remember: you can check the contents of an object by simply typing out its name



## Functions ---------------------------------

ten <- sqrt(weight_kg) #contain calculations wrapped into one command to type. 
#functions take "arguments": you have to tell them what to run their script against

round(3.14159) #don't have to assign

args(round) #the args() function will show you the required arguments of another function

?round #will show you the full help page for a function, so you can see what it does, 
#what argument it takes etc.

#Challenge 2: can you round the value 3.14159 to two decimal places?
# using args() should give a clue!



## Vectors and Data Types ---------------------------------

weight_g <- c(21, 34, 39, 54, 55) #use the combine function to join values into a vector object

length(weight_g) #explore vector
class(weight_g) #a vector can only contain one data type
str(weight_g) #find the structure of your object.
#our vector is numeric. 
#other options include: character (words), logical (TRUE or FALSE), integer etc.

animals <- c("mouse", "rat", "dog") #to create a character vector, use quotes


#Challenge 3: what data type will this vector become? You can check using class()
#challenge3 <- c(1, 2, 3, "4")



#R will convert (force) all values in a vector to the same data type.
#for this reason: try to keep one data type in each vector
#a data table / data frame is just multiple vectors (columns)
#this is helpful to remember when setting up your field sheets!

## Missing Data ---------------------------------

heights <- c(2, 4, 4, NA, 6)
mean(heights) #some functions cant handle NAs
mean(heights, na.rm = TRUE) #remove the NAs before calculating

#other ways to get a dataset without NAs:

heights[!is.na(heights)] #select for values where its NOT NA 
#[] square brackets are the base R way to select a subset of data --> called indexing
#! is an operator that reverses the function

na.omit(heights) #omit the NAs

heights[complete.cases(heights)] #select only complete cases

#Challenge 4: 
#1. Using this vector of heights in inches, create a new vector, heights_no_na, with the NAs removed.
#heights <- c(63, 69, 60, 65, NA, 68, 61, 70, 61, 59, 64, 69, 63, 63, NA, 72, 65, 64, 70, 63, 65)
#2. Use the function median() to calculate the median of the heights vector.
#BONUS: Use R to figure out how many people in the set are taller than 67 inches.



## Exploring Detection Extracts ---------------------------------
# what is a detection extract? https://members.oceantrack.org/data/otn-detection-extract-documentation-matched-to-animals 

#imports file into R. paste the filepath to the unzipped file here!

proj58_matched_2016 <- read_csv("../ACT_2021_data/ACT Network workshop datasets/proj58_matched_detections_2016.csv")

#read_csv() is from tidyverse's readr package --> you can also use read.csv() from base R but it created a dataframe (not tibble) so loads slower
#see https://link.medium.com/LtCV6ifpQbb 

#Note that the 'guess_max' argument can be useful if you have data that starts with a lot of null values.

head(proj58_matched_2016) #first 6 rows
View(proj58_matched_2016) #can also click on object in Environment window
str(proj58_matched_2016) #can see the type of each column (vector)
glimpse(proj58_matched_2016) #similar to str()

summary(proj58_matched_2016$latitude) #summary() is a base R function that will spit out some quick stats about a vector (column)
#the $ syntax is the way base R selects columns from a data frame

#Challenge 5: 
#1. What is is the class of the station column in proj58_matched_2016?
#2. How many rows and columns are in the proj58_matched_2016 dataset?

## Data Manipulation with dplyr --------------------------------------

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

#Challenge 6: 
#1. find the max lat and max longitude for animal "PROJ58-1170195-2014-05-31".
#2. find the min lat/long of each animal for detections occurring after April 2016.

## Joining Detection Extracts

proj58_matched_2017 <- read_csv("../ACT_2021_data/ACT Network workshop datasets/proj58_matched_detections_2017.csv", guess_max = 41880)
proj58_matched_full <- rbind(proj58_matched_2016, proj58_matched_2017) #join the two files

#release records for animals often appear in >1 year, this will remove the duplicates

proj58_matched_full <- proj58_matched_full %>% distinct() 

View(proj58_matched_full) 

proj58_matched_full <- proj58_matched_full %>% slice(1:10000) #subset our example data to help this workshop run smoother!

## Dealing with Datetimes in lubridate ---------------------------------

library(lubridate) 

proj58_matched_full %>% mutate(datecollected=ymd_hms(datecollected)) #Tells R to treat this column as a date, not number numbers

#as.POSIXct(proj58_matched_full$datecollected) #this is the base R way - if you ever see this function

#lubridate is amazing if you have a dataset with multiple datetime formats / timezone
#the function parse_date_time() can be used to specify multiple date formats if you have a dataset with mixed rows
#the function with_tz() can change timezone. accounts for daylight savings too!

#example code to change timezone:
#My_Data_Set %>% mutate(datetime = ymd_hms(datetime, tz = "America/Nassau")) #change your column to a datetime format, specifying TZ (eastern)
#My_Data_Set %>% mutate(datetime_utc = with_tz(datetime, tzone = "UTC")) #make new column called datetime_utc which is datetime converted to UTC


## Plotting with ggplot2 ---------------------------------

# basic formula:
# ggplot(data = <DATA>, mapping = aes(<MAPPINGS>)) +  <GEOM_FUNCTION>()

library(ggplot2) #tidyverse-style plotting, a very customizable plotting package


# Assign plot to a variable
proj58_matched_full_plot <- ggplot(data = proj58_matched_full, 
                                   mapping = aes(x = latitude, y = longitude)) #can assign a base plot to data

# Draw the plot 
proj58_matched_full_plot + 
  geom_point(alpha=0.1, 
             colour = "blue") 
#layer whatever geom you want onto your plot template
#very easy to explore diff geoms without re-typing
#alpha is a transparency argument in case points overlap

proj58_matched_full %>%  
  ggplot(aes(latitude, longitude)) + #aes = the aesthetic/mappings. x and y etc.
  geom_point() #geom = the type of plot

proj58_matched_full %>%  
  ggplot(aes(latitude, longitude, colour = receiver_group)) + #colour by receiver group! specify in the aesthetic
  geom_point()

#anything you specify in the aes() is applied to the actual data points/whole plot, 
#anything specified in geom() is applied to that layer only (colour, size...). sometimes you have >1 geom layer so this makes more sense!

#Challenge 7: try making a scatterplot showing the lat/long for animal "A69-1601-1363", 
# coloured by detection array



#Question: what other geoms are there? Try typing `geom_` into R to see what it suggests!

# Answering Qs for Reporting ---------------------------------

View(proj58_matched_full) #Check to make sure we already have our tag matches.

#Load in and join our array matches.

proj61_qual_2016 <- read_csv("../ACT_2021_data/ACT Network workshop datasets/Qualified_detecions_2016_2017/proj61_qualified_detections_2016.csv")
proj61_qual_2017 <- read_csv("../ACT_2021_data/ACT Network workshop datasets/Qualified_detecions_2016_2017/proj61_qualified_detections_2017.csv")
proj61_qual_16_17_full <- rbind(proj61_qual_2016, proj61_qual_2017) 

proj61_qual_16_17_full <- proj61_qual_16_17_full %>% slice(1:100000) #subset our example data for ease of analysis!

#need Array metadata
#These are saved as XLS/XLSX files, so we need a different library to read them in.
library(readxl)

proj61_deploy <- read_excel("../ACT_2021_data/ACT Network workshop datasets/Deploy_metadata_2016_2017/deploy_sercarray_proj61_2016_2017.xlsx", sheet = "Deployment", skip=3)
View(proj61_deploy)

#need Tag metadata

proj58_tag <- read_excel("../ACT_2021_data/ACT Network workshop datasets/Tag_Metadata/Proj58_Metadata_cownoseray.xls", sheet = "Tag Metadata", skip=4) 
View(proj58_tag)

#Need to skip rows in both cases to get the correct header because of the way the file is formatted.
#These numbers might be different for you depending on how many rows you need to skip. Check your files
#To find out for sure.

#remember: we learned how to switch timezone of datetime columns above, if that is something you need to do with your dataset!!

## Section 1: for Array Operators --------------------
#1. map GLATOS locations

#Load in ggmap to handle geographic mapping. 
library(ggmap)

#We'll use the CSV below to tell where our stations and receivers are.
full_receivers = read.csv('../ACT_2021_data/ACT Network workshop datasets/matos_FineToShare_stations_receivers_202104091205.csv')
full_receivers

#what are our columns called?
names(full_receivers)

#make a basemap for all of the stations, using the min/max deploy lat and longs as bounding box
base <- get_stamenmap(
  bbox = c(left = min(full_receivers$station_long), 
           bottom = min(full_receivers$station_lat), 
           right = max(full_receivers$station_long), 
           top = max(full_receivers$station_lat)),
  maptype = "terrain-background", 
  crop = FALSE,
  zoom = 8)

#filter for stations you want to plot - this is very customizable
full_receivers_plot <- full_receivers %>% 
  mutate(deploy_date=ymd(deploy_date)) %>% #make a datetime
  mutate(recovery_date=ymd(recovery_date)) %>% #make a datetime
  filter(!is.na(deploy_date)) %>% #no null deploys
  filter(deploy_date > '2011-07-03' & recovery_date < '2018-12-11') %>% #only looking at certain deployments, can add start/end dates here
  group_by(station_name) %>% 
  summarise(MeanLat=mean(station_lat), MeanLong=mean(station_long)) #get the mean location per station, in case there is >1 deployment

# you could choose to plot stations which are within a certain bounding box!
#to do this you would add another filter to the above data, before passing to the map
# ex: add this line after the mutate() clauses:
# filter(latitude <= 0.5 & latitude >= 24.5 & longitude <= 0.6 & longitude >= 34.9)


#add your stations onto your basemap
full_receivers_map <- 
  ggmap(base, extent='panel') + 
  ylab("Latitude") +
  xlab("Longitude") +
  geom_point(data = full_receivers_plot, #filtering for recent deployments
             aes(x = MeanLong,y = MeanLat, colour = station_name), #specify the data
             shape = 19, size = 2) #lots of aesthetic options here!

#view your receiver map!
full_receivers_map

#save your receiver map into your working directory
ggsave(plot = proj61_map, filename = "proj61_map.tiff", units="in", width=15, height=8) 
#can specify location, file type and dimensions


#2. map array locations
# we can do the same exact thing with the deployment metadata from OUR project only!

names(proj61_deploy)


base <- get_stamenmap(
  bbox = c(left = min(proj61_deploy$DEPLOY_LONG), 
           bottom = min(proj61_deploy$DEPLOY_LAT), 
           right = max(proj61_deploy$DEPLOY_LONG), 
           top = max(proj61_deploy$DEPLOY_LAT)),
  maptype = "terrain-background", 
  crop = FALSE,
  zoom = 8)

#filter for stations you want to plot - this is very customizable
proj61_deploy_plot <- proj61_deploy %>% 
  mutate(deploy_date=ymd_hms(`DEPLOY_DATE_TIME   (yyyy-mm-ddThh:mm:ss)`)) %>% #make a datetime
  mutate(recover_date=ymd_hms(`RECOVER_DATE_TIME (yyyy-mm-ddThh:mm:ss)`)) %>% #make a datetime
  filter(!is.na(deploy_date)) %>% #no null deploys
  filter(deploy_date > '2011-07-03' & recover_date < '2018-12-11') %>% #only looking at certain deployments, can add start/end dates here
  group_by(STATION_NO) %>% 
  summarise(MeanLat=mean(DEPLOY_LAT), MeanLong=mean(DEPLOY_LONG)) #get the mean location per station, in case there is >1 deployment

# you could choose to plot stations which are within a certain bounding box!
#to do this you would add another filter to the above data, before passing to the map
# ex: add this line after the mutate() clauses:
# filter(latitude <= 0.5 & latitude >= 24.5 & longitude <= 0.6 & longitude >= 34.9)


#add your stations onto your basemap
proj61_map <- 
  ggmap(base, extent='panel') + 
  ylab("Latitude") +
  xlab("Longitude") +
  geom_point(data = proj61_deploy_plot, #filtering for recent deployments
             aes(x = MeanLong,y = MeanLat, colour = STATION_NO), #specify the data
             shape = 19, size = 2) #lots of aesthetic options here!

#view your receiver map!
proj61_map

#save your receiver map into your working directory
ggsave(plot = proj61_map, filename = "proj61_map.tiff", units="in", width=15, height=8) 
#can specify location, file type and dimensions


#3. interactive map https://plotly.com/r/scatter-plots-on-maps/

library(plotly)

#set your basemap
geo_styling <- list(
  fitbounds = "locations", 
  visible = TRUE, #fits the bounds to your data!
  showland = TRUE,
  landcolor = toRGB("gray95"),
  subunitcolor = toRGB("gray85"),
  countrycolor = toRGB("gray85")
)

#decide what data you're going to use
proj61_map_plotly <- plot_geo(proj61_deploy_plot, lat = ~MeanLat, lon = ~MeanLong)  

#add your markers for the interactive map
proj61_map_plotly <- proj61_map_plotly %>% add_markers(
  text = ~paste(STATION_NO, MeanLat, MeanLong, sep = "<br />"),
  symbol = I("square"), size = I(8), hoverinfo = "text" 
)

#Add layout (title + geo stying)
proj61_map_plotly <- proj61_map_plotly %>% layout(
  title = 'Project 61 Deployments<br />(> 2011-07-03)', geo = geo_styling
)

#View map
proj61_map_plotly

#You might see the following warning: it just means that the plotly package has some updating to do
# Warning message:
# `arrange_()` is deprecated as of dplyr 0.7.0.
# Please use `arrange()` instead.
# See vignette('programming') for more help
# This warning is displayed once every 8 hours.
# Call `lifecycle::last_warnings()` to see where this warning was generated.

#4. How are my stations performing?

#How many of each animals did we detect from each collaborator, by station

proj61_qual_summary <- proj61_qual_16_17_full %>% 
  filter(datecollected > '2010-06-01') %>% #select timeframe, stations etc.
  group_by(trackercode, station, tag_contact_pi, tag_contact_poc) %>% 
  summarize(count = n()) %>% 
  select(trackercode, tag_contact_pi, tag_contact_poc, station, count)

#view our summary table

proj61_qual_summary #remember, this is just the first 10,000 rows!

#export our summary table

write_csv(proj61_qual_summary, "data/proj61_summary.csv", col_names = TRUE)


## Section 2: for Taggers --------------------

#5. map detections

base <- get_stamenmap(
  bbox = c(left = min(proj58_matched_full$longitude),
           bottom = min(proj58_matched_full$latitude), 
           right = max(proj58_matched_full$longitude), 
           top = max(proj58_matched_full$latitude)),
  maptype = "terrain-background", 
  crop = FALSE,
  zoom = 8)


#add your releases and detections onto your basemap

proj58_map <- 
  ggmap(base, extent='panel') +
  ylab("Latitude") +
  xlab("Longitude") +
  geom_point(data = proj58_matched_full, 
             aes(x = longitude,y = latitude), #specify the data
             colour = 'blue', shape = 19, size = 2) #lots of aesthetic options here!

#view your tagging map!

proj58_map



#6. interactive map https://plotly.com/r/scatter-plots-on-maps/ 

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
detctions_map_plotly <- plot_geo(proj58_matched_full, lat = ~latitude, lon = ~longitude) 

#add your markers for the interactive map
detctions_map_plotly <- detctions_map_plotly %>% add_markers(
  text = ~paste(catalognumber, commonname, paste("Date detected:", datecollected), 
                paste("Latitude:", latitude), paste("Longitude",longitude), 
                paste("Detected by:", detectedby), paste("Station:", station), 
                paste("Project:",collectioncode)),
  symbol = I("square"), size = I(8), hoverinfo = "text" 
)

#Add layout (title + geo stying)
detctions_map_plotly <- detctions_map_plotly %>% layout(
  title = 'Project 58 Detections', geo = geo_styling
)

#View map
detctions_map_plotly


#7. Summary of tagged animals

normDate <- Vectorize(function(x) {
  if (!is.na(suppressWarnings(as.numeric(x))))  # Win excel
    as.Date(as.numeric(x), origin="1899-12-30")
  else
    as.Date(x, format="%y/%m/%d")
})

res <- as.Date(normDate(proj58_tag$UTC_RELEASE_DATE_TIME[0:52]), origin="1970-01-01")
# summary of animals you've tagged

full_dates = c(ymd_hms(res, truncated = 3), ymd_hms(proj58_tag$UTC_RELEASE_DATE_TIME[53:89]))
View(full_dates)

proj58_tag <- proj58_tag %>%
  mutate(UTC_RELEASE_DATE_TIME = full_dates)

proj58_tag_summary <- proj58_tag %>% 
  #mutate(UTC_RELEASE_DATE_TIME = full_dates) %>% 
  #filter(UTC_RELEASE_DATE_TIME > '2019-06-01') %>% #select timeframe, specific animals etc.
  group_by(year = year(UTC_RELEASE_DATE_TIME), COMMON_NAME_E) %>% 
  summarize(count = n(), 
            Meanlength = mean(`LENGTH (m)`, na.rm=TRUE), 
            minlength= min(`LENGTH (m)`, na.rm=TRUE), 
            maxlength = max(`LENGTH (m)`, na.rm=TRUE), 
            MeanWeight = mean(`WEIGHT (kg)`, na.rm = TRUE)) 

#view our summary table

proj58_tag_summary


#8. detection attributes by year/month, per collector array or species

#Average location of each animal, without release records

proj58_matched_full %>% 
  group_by(catalognumber) %>% 
  summarize(NumberOfStations = n_distinct(station),
            AvgLat = mean(latitude),
            AvgLong =mean(longitude))

#Lets try to join to our tag metadata to get some more context!!
#First we need to make a tagname column in the tag metadata, and figure out the enddate of the tag battery
proj58_tag <- proj58_tag %>% 
  mutate(enddatetime = (ymd_hms(UTC_RELEASE_DATE_TIME) + days(EST_TAG_LIFE))) %>% #adding enddate
  mutate(tagname = paste(TAG_CODE_SPACE,TAG_ID_CODE, sep = '-')) #adding tagname column

#Now we join by tagname, to the detections without the release information

tag_joined_dets <- left_join(x = proj58_matched_full, y = proj58_tag, by = "tagname")

#make sure the redeployed tags have matched within their deployment period only

tag_joined_dets <- tag_joined_dets %>% 
  filter(datecollected >= UTC_RELEASE_DATE_TIME & datecollected <= enddatetime)

View(tag_joined_dets)

#Lets use this new dataframe to make summaries! Avg length per location

proj58_tag_det_summary <- tag_joined_dets %>% 
  group_by(detectedby, station, latitude, longitude)  %>%  
  summarise(AvgSize = mean(`LENGTH (m)`, na.rm=TRUE))

proj58_tag_det_summary

# count detections per transmitter, per array

proj58_matched_full %>% 
  group_by(catalognumber, station, commonname) %>% 
  summarize(count = n()) %>% 
  select(catalognumber, commonname, station, count)

# list all receivers each fish was seen on, and a number_of_receivers column too

receivers <- proj58_matched_full %>% 
  group_by(catalognumber) %>% 
  mutate(receivers = (list(unique(station)))) %>% #create a column with a list of the stations
  dplyr::select(catalognumber, receivers)  %>% #remove excess columns
  distinct_all() %>% #keep only one record of each
  mutate(number_of_receivers = sapply(receivers,length)) %>% #sapply: applies a function across a List - in this case we are applying length()
  as.data.frame() 

View(receivers)

#9. total detection counts by year/month

#try with tqcs_matched_10_11_full_no_release if you're feeling bold! takes ~30 secs

proj58_matched_full  %>% 
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
  ggtitle('Project 58 Detections by Month (2014-2017)')+ #title
  labs(fill = "Year") #legend title


## Other Example Plots -----------

# lots of information on this cheatsheet here https://rstudio.com/wp-content/uploads/2015/03/ggplot2-cheatsheet.pdf

# an easy abacus plot!

#Use the color scales in this package to make plots that are pretty, 
#better represent your data, easier to read by those with colorblindness, and print well in grey scale.
library(viridis)

proj58_matched_full %>%
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

proj58_matched_full %>% #doesnt work on the subsetted data, back to original dataset for this one
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
proj58_matched_full %>%
  ggplot(aes(longitude, latitude))+
  facet_wrap(~catalognumber)+ #make one plot per individual
  geom_violin()
#Warnings going on above.

View(proj58_matched_full)
abacus_animals <- 
  ggplot(data = proj58_matched_full, aes(x = datecollected, y = tagname, col = detectedby)) +
  geom_point() +
  ggtitle("Detections by animal") +
  theme(plot.title = element_text(face = "bold", hjust = 0.5)) +
  scale_color_viridis(discrete = TRUE)

abacus_animals

abacus_stations <- 
  ggplot(data = proj58_matched_full,  aes(x = datecollected, y = station, col = tagname)) +
  geom_point() +
  ggtitle("Detections by station") +
  theme(plot.title = element_text(face = "bold", hjust = 0.5)) +
  scale_color_viridis(discrete = TRUE)

abacus_stations #might be better with just a subet, huh??

#track movement using geom_path!!

#### Having trouble getting this working.
movMap <- 
  ggmap(base, extent = 'panel') + #use the BASE we set up before
  ylab("Latitude") +
  xlab("Longitude") +
  geom_path(data = proj58_matched_full, aes(x = longitude, y = latitude, col = commonname)) + #connect the dots with lines
  geom_point(data = proj58_matched_full, aes(x = longitude, y = latitude, col = commonname)) + #layer the stations back on
  scale_colour_manual(values = c("red", "blue"), name = "Species")+ #
  facet_wrap(~tagname, ncol = 6, nrow=1)+
  ggtitle("Inferred Animal Paths")

#to size the dots by number of detections you could do something like: size = (log(length(animal)id))?

movMap


# monthly latitudinal distribution of your animals (works best w >1 species)

proj58_matched_full %>%
  group_by(month=month(datecollected), tagname, commonname) %>% #make our groups
  summarise(meanlat=mean(latitude)) %>% #mean lat
  ggplot(aes(month %>% factor, meanlat, colour=commonname, fill=commonname))+ #the data is supplied, but no info on how to show it!
  geom_point(size=3, position="jitter")+   # draw data as points, and use jitter to help see all points instead of superimposition
  #coord_flip()+   #flip x y, not needed here
  scale_colour_manual(values = c("brown", "green"))+ #change the colour to represent the species better!
  scale_fill_manual(values = c("brown", "green"))+  #colour of the boxplot
  geom_boxplot()+ #another layer
  geom_violin(colour="black") #and one more layer


# per-individual contours - lots of plots: called facets!
proj58_matched_full %>%
  ggplot(aes(longitude, latitude))+
  facet_wrap(~tagname)+ #make one plot per individual
  geom_violin()


