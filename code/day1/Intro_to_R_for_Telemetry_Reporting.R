# Intro to R for Telemetry Reporting ---------------------------------
# FACT workshop 2020-12
# Instructor: Caitlin Bate

install.packages("tidyverse") # really neat collection of packages! https://www.tidyverse.org/ 
library(tidyverse)

setwd('C:/Users/ct991305/Documents/Workshop Material/2020-12-16-FACT') #set folder you're going to work in
getwd() #check working directory

## Operators ---------------------------------

3 + 5 #maths! including - , *, /

weight_kg <- 55 #assignment operator! for objects/variables. shortcut: alt + - 
weight_kg

weight_lb <- 2.2 * weight_kg #can assign output to an object. can use objects to do calculations

# Challenge 1:
# if we change the value of weight_kg to be 100, does the value of weight_lb also change automatically?
# remember: you can check the contents of an object by simply typing out its name

#Answer 1: no! you have to re-assign 2.2*weight_kg to the object weight_lb for it to update.
# The order you run your operations is very important, if you change something you may need to re-run everything!

## Functions ---------------------------------

ten <- sqrt(weight_kg) #contain calculations wrapped into one command to type. 
#functions take "arguments": you have to tell them what to run their script against

round(3.14159) #don't have to assign

args(round) #the args() function will show you the required arguments of another function

?round #will show you the full help page for a function, so you can see what it does, 
#what argument it takes etc.

#Challenge 2: can you round the value 3.14159 to two decimal places?
# using args() should give a clue!

#Answer 2:
# round(3.14159, 2) #the round function's second argument is the number of digits you want in the result
# round(3.14159, digits = 2) #same as above
# round(digits = 2, x = 3.14159) #when reordered you need to specify

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

#Answer 3: R will force all of these to be characters, since the number 4 has quotes around it! 
#Will always coerce data types following this struture: logical → numeric → character ← logical
#class(challenge3)

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

#Answer 4:
#1. heights_no_na <- heights[!is.na(heights)] 
  # or
  # heights_no_na <- na.omit(heights)
  # or
  # heights_no_na <- heights[complete.cases(heights)]
#2. median(heights, na.rm = TRUE)
#BONUS: heights_above_67 <- heights_no_na[heights_no_na > 67]
        #length(heights_above_67)

## Exploring Detection Extracts ---------------------------------

tqcs_matched_2010 <- read_csv("tqcs_matched_detections_2010/tqcs_matched_detections_2010.csv") #imports file into R
#read_csv() is from tidyverse's readr package --> you can also use read.csv() from base R but it created a dataframe (not tibble) so loads slower
#see https://link.medium.com/LtCV6ifpQbb 

head(tqcs_matched_2010) #first 6 rows
View(tqcs_matched_2010) #can also click on object in Environment window
str(tqcs_matched_2010) #can see the type of each column (vector)
glimpse(tqcs_matched_2010) #similar to str()

#important to know what functions will work on which, and which need to be converted

summary(tqcs_matched_2010$latitude) #summary() is a base R function that will spit out some quick stats about a vector (column)
#the $ syntax is the way base R selects columns from a data frame

#Challenge 5: 
#1. What is is the class of the station column in tqcs_matched_2010?
#2. How many rows and columns are in the tqcs_matched_2010 dataset?

#Answer 5: The column is a character, and there are 1,737,597 rows with 36 columns
# str(tqcs_matched_2010)
# or
# glimpse(tqcs_matched_2010)

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

#Answer 6:
#1. tqcs_matched_2010 %>% 
      #filter(catalognumber=="TQCS-1049258-2008-02-14") %>% 
      #summarise(MeanLat=mean(latitude), MeanLong=mean(longitude))

#2. tqcs_matched_2010 %>% 
      #filter(monthcollected == 7) %>% 
      #group_by(catalognumber) %>% 
      #summarise(MinLat=min(latitude), MinLong=min(longitude))


#Bring in data from RW, combine years, remove duplicate release lines 
#TODO - get code from Joy
#TODO - maybe we need to subset once we're all combined?

tqcs_matched_2011 <- read_csv("tqcs_matched_detections_2011/tqcs_matched_detections_2011.csv")
tqcs_matched_10_11 <- rbind(tqcs_matched_2010, tqcs_matched_2011) #join the two files

#TODO - remake tqcs 2011 extract!! needs 36 columns

View(tqcs_matched_10_11)

tqcs_matched_10_11_full <- tqcs_matched_10_11 #tuck the full dataset in a new object for safe keeping
tqcs_matched_10_11 <- tqcs_matched_10_11 %>% slice(1:100000) #subset our example data for ease of analysis!

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

tqcs_matched_10_11 %>%  
  ggplot(aes(latitude, longitude)) + #aes = the aesthetic. x and y etc.
  geom_point() #geom = the type of plot

tqcs_matched_10_11 %>%  
  ggplot(aes(latitude, longitude, colour = commonname)) + #colour by species!
  geom_point()

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

#Challenge 7: try making a scatterplot showing the lat/long for animal "TQCS-1049258-2008-02-14", coloured by detection array

#Answer 7: tqcs_matched_10_11 %>%  
            #filter(catalognumber=="TQCS-1049258-2008-02-14") %>% 
            #ggplot(aes(latitude, longitude, colour = detectedby)) + 
            #geom_point()

#Question: what other geoms are there? Try typing `geom_` into R to see what it suggests!



## Answering Qs for Reporting ---------------------------------
#TODO - convert to UTC from Eastern??

View(tqcs_matched_10_11) #already have our Tag matches

#need our Array matches, joined
teq_qual_2010 <- read_csv("teq_qualified_detections_2010_ish.csv")
teq_qual_2011 <- read_csv("teq_qualified_detections_2011_ish.csv")
teq_qual_10_11 <- rbind(teq_qual_2010, teq_qual_2011) 


teq_qual_10_11_full <- teq_qual_10_11 #tuck the full dataset in a new object for safe keeping
teq_qual_10_11 <- teq_qual_10_11 %>% slice(1:100000) #subset our example data for ease of analysis!


#need Array metadata
teq_deploy <- read.csv("TEQ_Deployments_201001_201201.csv")


#need Tag metadata
tqcs_tag <- read.csv("TQCS_metadata_tagging.csv") 
#TODO - show how to change timezone?

#TODO -Warning message:
#Missing column names filled in: 'X59' [59], 'X60' [60], 'X61' [61], 'X62' [62], 'X63' [63], 'X64' [64], 'X65' [65], 'X66' [66], 'X67' [67], 'X68' [68], 'X69' [69], 'X70' [70], 'X71' [71], 'X72' [72], 'X73' [73] 

#TODO - show temporal and location bounding

# Section 1: for Array Operators --------------------
#1. map array locations, by year/month - deploy metadata

library(ggmap)

#make a basemap for your stations, using the min/max deploy lat and longs as bounding box
base <- get_stamenmap(
  bbox = c(left = min(teq_deploy$DEPLOY_LONG), #TODO - fact format 
           bottom = min(teq_deploy$DEPLOY_LAT), 
           right = max(teq_deploy$DEPLOY_LONG), 
           top = max(teq_deploy$DEPLOY_LAT)),
  maptype = "terrain-background", 
  crop = FALSE,
  zoom = 8)

#filter for stations you want to plot
teq_deploy_plot <- teq_deploy %>% #TODO - fact format
  mutate(deploy_date=ymd_hms(DEPLOY_DATE_TIME....yyyy.mm.ddThh.mm.ss.)) %>% #make a datetime
  mutate(recover_date=ymd_hms(RECOVER_DATE_TIME..yyyy.mm.ddThh.mm.ss.)) %>% #make a datetime
  filter(!is.na(deploy_date)) %>% #no null deploys
  filter(deploy_date > 2010-07-03) %>% #only looking at certain deployments
  group_by(STATION_NO) %>% 
  summarise(MeanLat=mean(DEPLOY_LAT), MeanLong=mean(DEPLOY_LONG)) #get the mean location per station


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

#2. interactive map? https://plotly.com/r/scatter-plots-on-maps/

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


#3. table of attributes of animals detected - q extracts (n, commonname, sciname, owner)

teq_qual_summary <- teq_qual_10_11 %>% 
  filter(datecollected > '2010-06-01') %>% #select timeframe, stations etc.
  group_by(trackercode, scientificname, tag_contact_pi, tag_contact_poc) %>% 
  summarize(count = n()) %>% 
  select(trackercode, tag_contact_pi, tag_contact_poc, scientificname, count)

#view our summary table
teq_qual_summary #remember, this is just the first 10,000 rows!

#export our summary table
write_csv(teq_qual_summary, "teq_detection_summary_June2010_to_Dec2011.csv", col_names = TRUE)


#4. detection attributes by year/month
#TODO - what attributes? dets per station?

teq_det_summary  <- teq_qual_10_11  %>% #TODO - FACT format??
  mutate(datecollected=ymd_hms(datecollected))  %>% 
  group_by(station, year = year(datecollected), month = month(datecollected)) %>% 
  summarize(count =n())

teq_det_summary #number of dets per month/year per station, remember: this is a subset!


#5. total detection counts by year
#library(zoo)
#library(scales)
#library(reshape2)
#TODO - figure out if i need those ^
  
teq_qual_10_11  %>% #try with teq_qual_10_11_full if you're feeling bold! takes about 1 min to run on a fast machine
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

#6. map detections and releases - t extracts
#TODO - use unfiltered dataset here to keep release locations in!

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
  geom_point(data = tqcs_matched_10_11, #filtering for recent deployments
             aes(x = longitude,y = latitude), #specify the data
             colour = 'blue', shape = 19, size = 2) #lots of aesthetic options here!

#view your tagging map!
tqcs_map


#7. interactive map ^? https://plotly.com/r/scatter-plots-on-maps/ 

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
  title = 'TQCS Detections<br />(2018-2019)', geo = geo_styling
)

#View map
tqcs_map_plotly


#8. table of attributes of animals (all which are in SC notebook plus arrayowner)

#TODO - what attributes? do we need to join tag meta w dets? #DO WE WANNA?????

# summary of animals you've tagged
tqcs_tag_summary <- tqcs_tag %>% 
  mutate(UTC_RELEASE_DATE_TIME = ymd_hms(UTC_RELEASE_DATE_TIME)) %>% 
  #filter(UTC_RELEASE_DATE_TIME > '2019-06-01') %>% #select timeframe, specific animals etc.
  group_by(year = year(UTC_RELEASE_DATE_TIME), COMMON_NAME_E) %>% 
  summarize(count = n(), 
            Meanlength = mean(LENGTH..m., na.rm=TRUE), 
            minlength= min(LENGTH..m.), 
            maxlength = max(LENGTH..m.), 
            MeanWeight = mean(WEIGHT..kg., na.rm = TRUE)) 

#view our summary table
tqcs_tag_summary


#9. detection attributes by year/month, per collector array or species

#TODO- join to tag meta? what kind of attributes?

#10. total detection counts by year

#TODO - by year?? by year and month??

tqcs_matched_10_11 %>% 
  group_by(year = year(datecollected), month = month(datecollected)) %>% 
  summarize(count = n()) %>% 
  ggplot(aes(month %>% as.factor(), count))+ #TODO - add years in here, see what we did for Q extracts
  geom_col()+
  xlab("Month")+
  ylab("Total Detection Count")+
  ggtitle('TQCS Detections by Month (2010-2011')


# Other Example Plots -----------

# monthly latitudinal distribution of blue sharks (works best w >1 species)

tqcs_matched_10_11 %>%
  group_by(m=month(datecollected), catalognumber, scientificname) %>% #make our groups
  summarise(mean=mean(latitude)) %>% #mean lat
  ggplot(aes(m %>% factor, mean, colour=scientificname, fill=scientificname))+ #the data is supplied, but no info on how to show it!
  geom_point(size=3, position="jitter")+   # draw data as points, and use jitter to help see all points instead of superimposition
  #coord_flip()+   #flip x y, not needed here
  scale_colour_manual(values = "blue")+ #change the colour to represent the species better!
  scale_fill_manual(values = "grey")+ 
  geom_boxplot()+ #another layer
  geom_violin(colour="black") #aaaaaand another layer


#There are other ways to present a summary of data like this that we might have chosen. 
#geom_density2d() will give us a KDE for our data points and give us some contours across our chosen plot axes.

tqcs_matched_10_11 %>% #doesnt work on the subsetted data, back to original dataset for this one
  group_by(m=month(datecollected), catalognumber, scientificname) %>%
  summarise(mean=mean(latitude)) %>%
  ggplot(aes(m, mean, colour=scientificname, fill=scientificname))+
  geom_point(size=3, position="jitter")+
  scale_colour_manual(values = "blue")+
  scale_fill_manual(values = "grey")+
  geom_density2d(size=7, lty=1) #this is the only difference from the plot above 

#anything you specify in the aes() is applied to the actual data points/whole plot, 
#anything specified in geom() is applied to that layer only (colour, size...)

# per-individual density contours - lots of plots: called facets!
tqcs_matched_10_11 %>%
  ggplot(aes(latitude, longitude))+
  facet_wrap(~catalognumber)+ #make one plot per individual
  geom_violin()



