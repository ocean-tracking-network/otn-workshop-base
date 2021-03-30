# Intro to R for Telemetry Summaries ---------------------------------
# GLATOS workshop 2021-03-30
# Instructors: Bruce Delo and Caitlin Bate


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
#Will always coerce data types following this struture: logical → numeric → character ← logical
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
#1. What is is the class of the station column in lamprey_dets?
#2. How many rows and columns are in the lamprey_dets dataset?

#Answer 5: The column is a character, and there are 5,923 rows with 30 columns
str(lamprey_dets)
# or
glimpse(lamprey_dets)




# Challenge 6 ----
#1. find the max lat and max longitude for animal "A69-1601-1363"
#2. find the min lat/long of each animal for detections occurring in July

#Answer 6:
#1. 
lamprey_dets %>% 
  filter(animal_id=="A69-1601-1363") %>% 
  summarise(MaxLat=max(deploy_lat), MaxLong=max(deploy_long))

#2. 
lamprey_dets %>% 
  filter(detection_timestamp_utc >= "2012-07-01 00:00:00" | detection_timestamp_utc < "2012-08-01 00:00:00" ) %>% 
  group_by(animal_id) %>% 
  summarise(MinLat=min(deploy_lat), MinLong=min(deploy_long))




# Challenge 7 ----
# try making a scatterplot showing the lat/long for animal "A69-1601-1363", 
# coloured by detection array

#Answer 7: 
lamprey_dets %>%  
  filter(animal_id=="A69-1601-1363") %>% 
  ggplot(aes(deploy_lat, deploy_long, colour = glatos_array)) + 
  geom_point()

#Question: what other geoms are there? Try typing `geom_` into R to see what it suggests!
