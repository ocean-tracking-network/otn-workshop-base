# Intro to R for Telemetry Summaries ---------------------------------
# Challenges and Answers

# Challenge 1 ----
# if we change the value of weight_kg to be 100, does the value of weight_lb also change automatically?
# remember: you can check the contents of an object by simply typing out its name

#Answer 1: no! you have to re-assign 2.2*weight_kg to the object weight_lb for it to update.
# The order you run your operations is very important, if you change something you may need to re-run everything!

weight_kg <- 100

weight_lb #didnt change!

weight_lb <- 2.2 * weight_kg #now its updated




# Challenge 2 -----
# can you round the value 3.14159 to two decimal places?
# using args() should give a clue!

#Answer 2:
round(3.14159, 2) #the round function's second argument is the number of digits you want in the result
round(3.14159, digits = 2) #same as above
round(digits = 2, x = 3.14159) #when reordered you need to specify




# Challenge 3 ----
# what data type will this vector become? You can check using class()
challenge3 <- c(1, 2, 3, "4")

#Answer 3: R will force all of these to be characters, since the number 4 has quotes around it! 
#Will always coerce data types following this structure: 
#logical --> numeric -->character <-- logical
class(challenge3)




# Challenge 4 ---- 
#1. Using this vector of heights in inches, create a new vector, heights_no_na, with the NAs removed.
heights <- c(63, 69, 60, 65, NA, 68, 61, 70, 61, 59, 64, 69, 63, 63, NA, 72, 65, 64, 70, 63, 65)
#2. Use the function median() to calculate the median of the heights vector.
#BONUS: Use R to figure out how many people in the set are taller than 67 inches.

#Answer 4:
#1. 
heights_no_na <- heights[!is.na(heights)] 
# or
heights_no_na <- na.omit(heights)
# or
heights_no_na <- heights[complete.cases(heights)]

#2. 
median(heights, na.rm = TRUE)

#BONUS: 
heights_above_67 <- heights_no_na[heights_no_na > 67]
length(heights_above_67)



# Challenge 5 ----
#1. What is is the class of the station column in nsbs_matched_2021?
#2. How many rows and columns are in the nsbs_matched_2021 dataset?

#Answer 5: The column is a character, and there are 2,938  rows with 29 columns
str(nsbs_matched_2021)
# or
glimpse(nsbs_matched_2021)



# Challenge 6 ----
#1. Find the max lat and max decimalLongitude for animal “NSBS-1393332-2021-08-05”.
#2. Find the min lat/long of each animal for detections occurring in/after April.

#Answer 6:
#1. 
nsbs_matched_2021 %>%
  filter(catalogNumber=="NSBS-1393332-2021-08-05") %>%
  summarise(MaxLat=max(decimalLatitude), MaxLong=max(decimalLongitude))

#2. 
nsbs_matched_2021 %>%
  filter(month(dateCollectedUTC) >= 4 ) %>%
  group_by(catalogNumber) %>%
  summarise(MinLat=min(decimalLatitude), MinLong=min(decimalLongitude))


# Challenge 7 ----
#Try making a scatterplot showing the lat/long for animal “NSBS-1393332-2021-08-05”, 
#coloured by detection array

#Answer 7: 
nsbs_matched_full %>%  
  filter(catalogNumber=="NSBS-1393332-2021-08-05") %>%
  ggplot(aes(decimalLongitude, decimalLatitude, colour = detectedBy)) +
  geom_point()

#Question: what other geoms are there? Try typing `geom_` into R to see what it suggests!