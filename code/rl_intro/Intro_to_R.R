# Intro to R ---------------------------------
# SPG workshop 2020-07
# Instructor: Caitlin Bate


install.packages("tidyverse") # really neat collection of packages! https://www.tidyverse.org/ 
library('tidyverse')

setwd('C:/Users/ct991305/Documents/Workshop Material/SPG_July_2020') #set folder you're going to work in
getwd() #check working directory

## operators ---------------------------------

3 + 5 #maths! including - , *, /

weight_kg <- 55 #assignment operator! for objects/variables. shortcut: alt + - 

weight_lb <- 2.2 * weight_kg #can assign output to an object. can use objects to do calculations

## functions ---------------------------------

ten <- sqrt(weight_kg) #contain calculations wrapped into one command to type. 
                       #functions take "arguments": you have to tell them what to run their script against

round(3.14159) #don't have to assign

args(round) #the args() function will show you the required arguments of another function

?round #will show you the full help page for a function, so you can see what it does, 
       #what argument it takes etc.

round(3.14159, 2) #the round function's second argument is the number of digits you want in the result
round(3.14159, digits = 2) #same as above
round(digits = 2, x = 3.14159) #when reordered you need to specify

## vectors and data types ---------------------------------

weight_g <- c(21, 34, 39, 54, 55) #use the combine function to join values into a vector object

length(weight_g) #explore vector
class(weight_g) #a vector can only contain one data type
str(weight_g) #find the structure of your object.
              #our vector is numeric. 
              #other options include: character (words), logical (TRUE or FALSE), integer etc.

animals <- c("mouse", "rat", "dog") #to create a character vector, use quotes

#R will convert (force) all values in a vector to the same data type.
#for this reason: try to keep one data type in each vector
#a data table / data frame is just multiple vectors (columns)

## subsetting ---------------------------------

animals #calling your object will print it out
animals[2] #square brackets = indexing. selects the 2nd value in your vector

weight_g > 50 #conditional indexing: selects based on criteria
weight_g[weight_g <=30 | weight_g == 55] #many new operators here!  
                                         #<= less than or equal to, | "or", == equal to
weight_g[weight_g >= 30 & weight_g == 21] #  >=  greater than or equal to, & "and" 
                                          # this particular example give 0 results - why?

## missing data ---------------------------------

heights <- c(2, 4, 4, NA, 6)
mean(heights) #some functions cant handle NAs
mean(heights, na.rm = TRUE) #remove the NAs before calculating

#other ways to get a dataset without NAs:
heights[!is.na(heights)] #indexes for values where its NOT NA 
                         #! is an operator that reverses the function
na.omit(heights) #omit the NAs
heights[complete.cases(heights)] #select only complete cases

## exploring data frames ---------------------------------

load("seaTrout.rda") #imports file into R

head(seaTrout) #first 6 rows
View(seaTrout) #can also click on object in Environment window
str(seaTrout) #can see the type of each column (vector), 
              #important to know what functions will work on which, and which need to be converted

seaTrout[,c(7)] #selects column 7. need an x and y coordinate

library(dplyr) #can use tidyverse package dplyr to do exploration on dataframes in a nicer way
seaTrout %>% dplyr::select(7) 

# %>% is a "pipe" which allows you to join functions together in sequence. 
#it can be read as "and then". shortcut: ctrl + shift + m
# dplyr::select this syntax is to specify that we want the select function from the dplyr package. 
#often functions are named the same but do diff things

seaTrout[c(1:5),] #selects rows 1 to 5
seaTrout %>% slice(1:5) #dplyr way

seaTrout_full = seaTrout
seaTrout <- seaTrout %>% slice(1:100000) #make dataframe smaller, so that it will be easier to work with later

nrow(data.frame(unique(seaTrout$Species))) #number of species, in base R
seaTrout %>% distinct(Species) %>% nrow #number of species in dplyr!

seaTrout[which(seaTrout$Species=="Trout"),] #filtering a subset of data (only species = AB)
seaTrout %>% filter(Species=="Trout") #filtering in dplyr!

tapply(seaTrout$lon, seaTrout$tag.ID, mean) #get the mean value across a column, in base R
seaTrout %>%
  group_by(tag.ID) %>%
  summarise(mean=mean(lon)) #uses pipes and dplyr functions to do this!

## datetimes ---------------------------------

as.POSIXct(seaTrout$DateTime) #Tells R to treat this column as a date, not number numbers

library(lubridate) #can use tidyverse package lubridate to work with dates easier
seaTrout %>% mutate(DateTime=ymd_hms(DateTime))

#lubridate is amazing if you have a dataset with multiple datetime formats / timezone
#the function parse_date_time() can be used to specify multiple date formats
#the function with_tz() can change timezone. accounts for daylight savings too!
  #example code:
      #datetime <- ymd_hms(recover_date_Eastern$datetime, tz = "America/Nassau") #specify ymd_hms format and current TZ (eastern)
      #datetime_utc <- with_tz(datetime, tzone = "UTC") #convert timezone to UTC

## plots ---------------------------------

plot(seaTrout$lon, seaTrout$lat)  #base R

library(ggplot2) #tidyverse-style plotting, a very customizable plotting package
seaTrout %>%  
  ggplot(aes(lon, lat)) + #aes = the aesthetic. x and y etc.
  geom_point() #geom = the type of plot


## intro to ggplot ---------------------------------

#ggplot(data = <DATA>, mapping = aes(<MAPPINGS>)) +  <GEOM_FUNCTION>()

# Assign plot to a variable
seaTroutplot <- ggplot(data = seaTrout, 
                       mapping = aes(x = lon, y = lat)) #can assign a base plot to data

#Draw the plot
seaTroutplot + 
  geom_point(alpha=0.1, 
             color = "blue") #layer whatever geom you want onto your plot template
                             #very easy to explore diff geoms without re-typing
                             #alpha is a transparency argument in case points overlap



# monthly longitudinal distribution of salmon smolts and sea trout

seaTrout %>%
  group_by(m=month(DateTime), tag.ID, Species) %>% #make our groups
  summarise(mean=mean(lon)) %>% #mean lon
  ggplot(aes(m %>% factor, mean, colour=Species, fill=Species))+ #the data is supplied, but no info on how to show it!
  geom_point(size=3, position="jitter")+   # draw data as points, and use jitter to help see all points instead of superimposition
  coord_flip()+   #flip x y    
  scale_colour_manual(values=c("grey", "gold"))+  # change the color palette to reflect species a bit better
  scale_fill_manual(values=c("grey", "gold"))+ 
  geom_boxplot()+ #another layer
  geom_violin(colour="black") #aaaaaand another layer


#There are other ways to present a summary of data like this that we might have chosen. 
#geom_density2d() will give us a KDE for our data points and give us some contours across our chosen plot axes.

seaTrout_full %>% #doesnt work on the subsetted data, back to original dataset for this one
  group_by(m=month(DateTime), tag.ID, Species) %>%
  summarise(mean=mean(lon)) %>%
  ggplot(aes(m, mean, colour=Species, fill=Species))+
  geom_point(size=3, position="jitter")+
  coord_flip()+
  scale_colour_manual(values=c("grey", "gold"))+
  scale_fill_manual(values=c("grey", "gold"))+
  geom_density2d(size=2, lty=1) #this is the only difference from the plot above 

#we might like to use multiple plots for each subset, or facets, for our two distinct species,
#as they're hard to see on top of one another in this way. 

seaTrout %>% #maybe try with full dataset seaTrout1 as well, up to you
  group_by(m=month(DateTime), tag.ID, Species) %>%
  summarise(mean=mean(lon)) %>%
  ggplot(aes(m, mean))+
  stat_density_2d(aes(fill = stat(nlevel)), geom = "polygon")+ #new plot type
  geom_point(size=3, position="jitter")+
  coord_flip()+
  facet_wrap(~Species)+ #faceting our plot by species! we already grouped  them
  scale_fill_viridis_c() +
  labs(x="Mean Month", y="Longitude (UTM 33)") #axis labeling

# per-individual density contours - lots of facets!
seaTrout %>%
  ggplot(aes(lon, lat))+
  stat_density_2d(aes(fill = stat(nlevel)), geom = "polygon")+
  facet_wrap(~tag.ID)


## new R, new dplyr ---------------------------------
#just an FYI, there is a new dplyr and new R version out recently! 
#see full changes w R version 4.0 here https://cran.r-project.org/doc/manuals/r-devel/NEWS.html
#see the full changes to dplyr 1.0 here https://www.tidyverse.org/blog/2020/06/dplyr-1-0-0/ 
#the changes as I recognize them:
#1. read.csv(), data.frame(), read.table() no longer have `StringsAsFactors = TRUE` as default. 
# check data types on import. 
# now functions same as the dplyr read_csv() function
#2. packages need to be re-installed under R version 4.0+
#3. some packages won't work (yet) on R 4.0+
