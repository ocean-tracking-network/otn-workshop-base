# Intro to R for Telemetry Reporting ---------------------------------
# FACT workshop 2020-12-16
# Instructor: Caitlin Bate

install.packages("tidyverse") # really neat collection of packages! https://www.tidyverse.org/ 
library(tidyverse)

setwd('C:/Users/ct991305/Documents/Workshop Material/2020-12-17-telemetry-packages-FACT/') #set folder you're going to work in
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

tqcs_matched_2010 <- read_csv("data/tqcs_matched_detections_2010.csv", guess_max = 117172) #imports file into R. paste the filepath to the unzipped file here!
#read_csv() is from tidyverse's readr package --> you can also use read.csv() from base R but it created a dataframe (not tibble) so loads slower
#see https://link.medium.com/LtCV6ifpQbb 
#the guess_max argument is helpful when there are many rows of NAs at the top. R will not assign a data type to that columns until it reaches the max guess.
#I chose to use this here because I got the following warning from read_csv()
# Warning: 82 parsing failures.
#   row            col           expected actual                                    file
#117172 bottom_depth   1/0/T/F/TRUE/FALSE   5    'data/tqcs_matched_detections_2010.csv'
#117172 receiver_depth 1/0/T/F/TRUE/FALSE   4    'data/tqcs_matched_detections_2010.csv'
#122664 bottom_depth   1/0/T/F/TRUE/FALSE   17.5 'data/tqcs_matched_detections_2010.csv'
#122664 receiver_depth 1/0/T/F/TRUE/FALSE   16.5 'data/tqcs_matched_detections_2010.csv'
#162757 bottom_depth   1/0/T/F/TRUE/FALSE   6    'data/tqcs_matched_detections_2010.csv'

head(tqcs_matched_2010) #first 6 rows
View(tqcs_matched_2010) #can also click on object in Environment window
str(tqcs_matched_2010) #can see the type of each column (vector)
glimpse(tqcs_matched_2010) #similar to str()


summary(tqcs_matched_2010$latitude) #summary() is a base R function that will spit out some quick stats about a vector (column)
#the $ syntax is the way base R selects columns from a data frame

#Challenge 5: 
#1. What is is the class of the station column in tqcs_matched_2010?
#2. How many rows and columns are in the tqcs_matched_2010 dataset?



## Data Manipulation with dplyr --------------------------------------

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





#Bring in data from RW, combine years, remove duplicate release lines 

tqcs_matched_2011 <- read_csv("data/tqcs_matched_detections_2011.csv", guess_max = 41880) #likley need to add a guess_max = 41880
tqcs_matched_10_11_full <- rbind(tqcs_matched_2010, tqcs_matched_2011) #join the two files

#release records for animals often appear in >1 year, this will remove the duplicates
tqcs_matched_10_11_full <- tqcs_matched_10_11_full %>% distinct() 

View(tqcs_matched_10_11_full)

tqcs_matched_10_11 <- tqcs_matched_10_11_full %>% slice(1:100000) #subset our example data for ease of analysis!

## Dealing with Datetimes in lubridate ---------------------------------

library(lubridate) 

tqcs_matched_10_11 %>% mutate(datecollected=ymd_hms(datecollected)) #Tells R to treat this column as a date, not number numbers

#as.POSIXct(tqcs_matched_2010$datecollected) #this is the base R way - if you ever see this function

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
tqcs_10_11_plot <- ggplot(data = tqcs_matched_10_11, 
                  mapping = aes(x = latitude, y = longitude)) #can assign a base plot to data

# Draw the plot
tqcs_10_11_plot + 
  geom_point(alpha=0.1, 
             colour = "blue") 
#layer whatever geom you want onto your plot template
#very easy to explore diff geoms without re-typing
#alpha is a transparency argument in case points overlap

tqcs_matched_10_11 %>%  
  ggplot(aes(latitude, longitude)) + #aes = the aesthetic. x and y etc.
  geom_point() #geom = the type of plot

tqcs_matched_10_11 %>%  
  ggplot(aes(latitude, longitude, colour = commonname)) + #colour by species!
  geom_point()

#anything you specify in the aes() is applied to the actual data points/whole plot, 
#anything specified in geom() is applied to that layer only (colour, size...)

#Challenge 7: try making a scatterplot showing the lat/long for animal "TQCS-1049258-2008-02-14", coloured by detection array





#Question: what other geoms are there? Try typing `geom_` into R to see what it suggests!



## Answering Qs for Reporting ---------------------------------

View(tqcs_matched_10_11) #already have our Tag matches

#need our Array matches, joined
teq_qual_2010 <- read_csv("data/teq_qualified_detections_2010_ish.csv")
teq_qual_2011 <- read_csv("data/teq_qualified_detections_2011_ish.csv")
teq_qual_10_11_full <- rbind(teq_qual_2010, teq_qual_2011) 

teq_qual_10_11 <- teq_qual_10_11_full %>% slice(1:100000) #subset our example data for ease of analysis!


#need Array metadata
teq_deploy <- read.csv("data/TEQ_Deployments_201001_201201.csv")
View(teq_deploy)

#need Tag metadata
tqcs_tag <- read.csv("data/TQCS_metadata_tagging.csv") 
View(tqcs_tag)

#remember: we learned how to switch timezone of datetime columns above, if that is something you need to do with your dataset!!


# Section 1: for Array Operators --------------------
#1. map array locations

library(ggmap)

#make a basemap for your stations, using the min/max deploy lat and longs as bounding box
#what are our columns called?
names(teq_deploy)


base <- get_stamenmap(
  bbox = c(left = min(teq_deploy$DEPLOY_LONG), 
           bottom = min(teq_deploy$DEPLOY_LAT), 
           right = max(teq_deploy$DEPLOY_LONG), 
           top = max(teq_deploy$DEPLOY_LAT)),
  maptype = "terrain-background", 
  crop = FALSE,
  zoom = 8)

#filter for stations you want to plot - this is very customizable
teq_deploy_plot <- teq_deploy %>% 
  mutate(deploy_date=ymd_hms(DEPLOY_DATE_TIME....yyyy.mm.ddThh.mm.ss.)) %>% #make a datetime
  mutate(recover_date=ymd_hms(RECOVER_DATE_TIME..yyyy.mm.ddThh.mm.ss.)) %>% #make a datetime
  filter(!is.na(deploy_date)) %>% #no null deploys
  filter(deploy_date > 2010-07-03) %>% #only looking at certain deployments
  group_by(STATION_NO) %>% 
  summarise(MeanLat=mean(DEPLOY_LAT), MeanLong=mean(DEPLOY_LONG)) #get the mean location per station

# you could choose to plot stations which are within a certain bounding box!
#to do this you would add another filter to the above data, before passing to the map
# ex: add this line after the mutate() clauses:
# filter(latitude <= 0.5 & latitude >= 24.5 & longitude <= 0.6 & longitude >= 34.9)



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
ggsave(plot = teq_map, file = "code/day1/teq_map.tiff", units="in", width=15, height=8)

#2. interactive map https://plotly.com/r/scatter-plots-on-maps/

library(plotly)

#set your basemap
geo_styling <- list(
  fitbounds = "locations", visible = TRUE, #fits the bounds to your data!
  showland = TRUE,
  landcolor = toRGB("gray95"),
  subunitcolor = toRGB("gray85"),
  countrycolor = toRGB("gray85")
)

#decide what data you're going to use
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

#You might see the following warning: it just means that the plotly package has some updating to do
  # Warning message:
  # `arrange_()` is deprecated as of dplyr 0.7.0.
  # Please use `arrange()` instead.
  # See vignette('programming') for more help
  # This warning is displayed once every 8 hours.
  # Call `lifecycle::last_warnings()` to see where this warning was generated. 


#3. summary of animals detected

teq_qual_summary <- teq_qual_10_11 %>% 
  filter(datecollected > '2010-06-01') %>% #select timeframe, stations etc.
  group_by(trackercode, scientificname, tag_contact_pi, tag_contact_poc) %>% 
  summarize(count = n()) %>% 
  select(trackercode, tag_contact_pi, tag_contact_poc, scientificname, count)

#view our summary table
teq_qual_summary #remember, this is just the first 10,000 rows!

#export our summary table
write_csv(teq_qual_summary, "code/day1/teq_detection_summary_June2010_to_Dec2011.csv", col_names = TRUE)


#4. detection attributes by year/month

teq_det_summary  <- teq_qual_10_11  %>% 
  mutate(datecollected=ymd_hms(datecollected))  %>% 
  group_by(station, year = year(datecollected), month = month(datecollected)) %>% 
  summarize(count =n())

teq_det_summary #number of dets per month/year per station, remember: this is a subset!

teq_anim_summary  <- teq_qual_10_11  %>% 
  mutate(datecollected=ymd_hms(datecollected))  %>% 
  group_by(station, year = year(datecollected), month = month(datecollected), scientificname) %>% 
  summarize(count =n())

teq_anim_summary #number of dets per month/year per station & species, remember: this is a subset!

#5. plotting detection counts

teq_qual_10_11 %>% #try with teq_qual_10_11_full if you're feeling bold! takes about 1 min to run on a fast machine
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

       
# Section 2: for Taggers --------------------

#optional subsetted dataset to use: detections with releases filtered out!

tqcs_matched_10_11_no_release <- tqcs_matched_10_11 %>% 
  filter(receiver != "release")

#optional full dataset to use: detections with releases filtered out!

tqcs_matched_10_11_full_no_release <- tqcs_matched_10_11_full %>% 
  filter(receiver != "release")


#6. map detections and releases 

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


#7. interactive map https://plotly.com/r/scatter-plots-on-maps/ 

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


#8. Summary of tagged animals

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


#9. detection attributes by year/month, per collector array or species

#Average location of each animal!
tqcs_matched_10_11_no_release %>% 
  group_by(catalognumber) %>% 
  summarize(NumberOfStations = n_distinct(station),
            AvgLat = mean(latitude),
            AvgLong =mean(longitude))

#Lets try to join to our tag metadata to get some more context!!
#First we need to make a tagname column, and figure out the enddate of the tag battery

tqcs_tag <- tqcs_tag %>% 
  mutate(enddatetime = (ymd_hms(UTC_RELEASE_DATE_TIME) + days(EST_TAG_LIFE))) %>% 
  mutate(tagname = paste(TAG_CODE_SPACE,TAG_ID_CODE, sep = '-'))

#Now we join by tagname
tag_joined_dets <-  left_join(x = tqcs_matched_10_11_no_release, y = tqcs_tag, by = "tagname")

#make sure the redeployed tags have matched within their deployment period only
tag_joined_dets <- tag_joined_dets %>% 
  filter(datecollected >= UTC_RELEASE_DATE_TIME & datecollected <= enddatetime)

View(tag_joined_dets)

#Lets use this new dataframe to make summaries! Avg length per location
tqcs_tag_det_summary <- tag_joined_dets %>% 
  mutate(datecollected = ymd_hms(datecollected)) %>% 
  group_by(detectedby, station, latitude, longitude)  %>%  
  summarise(AvgSize = mean(LENGTH..m., na.rm=TRUE))

tqcs_tag_det_summary


#10. total detection counts by year/month

tqcs_matched_10_11_no_release  %>% #try with tqcs_matched_10_11_full_no_release if you're feeling bold! takes ~30 secs
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







# Other Example Plots -----------

# monthly latitudinal distribution of your animals (works best w >1 species)

tqcs_matched_10_11 %>%
  group_by(month=month(datecollected), catalognumber, scientificname) %>% #make our groups
  summarise(meanlat=mean(latitude)) %>% #mean lat
  ggplot(aes(month %>% factor, meanlat, colour=scientificname, fill=scientificname))+ #the data is supplied, but no info on how to show it!
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


