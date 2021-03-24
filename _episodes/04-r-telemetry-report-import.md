---
title: Telemetry Reports - Imports
teaching: 10
exercises: 0
questions:
    - "What datasets do I need from the Node?"
    - "How do I import all the datasets?"
---

## Importing all the datasets
Now that we have an idea of what an exploratory workflow might look like with Tidyverse libraries like `dplyr` and `ggplot2`, let's look at how we might implement a common telemetry workflow using these tools.

~~~
View(lamprey_dets) #already have our Lamprey tag matches


#import walleye dets
walleye_dets <- read_csv("inst_extdata_walleye_detections.csv", guess_max = 9595) #remember guess_max from prev section!

#Warning: 9595 parsing failures.
#row          col           expected actual                                  file
#3047 sensor_value 1/0/T/F/TRUE/FALSE    11  'inst_extdata_walleye_detections.csv'
#3047 sensor_unit  1/0/T/F/TRUE/FALSE    ADC 'inst_extdata_walleye_detections.csv'
#3048 sensor_value 1/0/T/F/TRUE/FALSE    11  'inst_extdata_walleye_detections.csv'
#3048 sensor_unit  1/0/T/F/TRUE/FALSE    ADC 'inst_extdata_walleye_detections.csv'
#3049 sensor_value 1/0/T/F/TRUE/FALSE    11  'inst_extdata_walleye_detections.csv'

#lets join these two detection files together!
all_dets <- rbind(lamprey_dets, walleye_dets)


# lets import GLATOS receiver station data for the whole network

glatos_receivers <- read_csv("inst_extdata_sample_receivers.csv")
View(glatos_receivers)

#Lets import our workbook now!

library(readxl)

walleye_deploy <- read_excel('inst_extdata_walleye_workbook.xlsm', sheet = 'Deployment') #pull in deploy
View(walleye_deploy)

walleye_recovery <- read_excel('inst_extdata_walleye_workbook.xlsm', sheet = 'Recovery') #pull in recovery
View(walleye_recovery)

#join the deploy and recovery sheets together

walleye_recovery <- walleye_recovery %>% rename(INS_SERIAL_NO = INS_SERIAL_NUMBER) #first, rename INS_SERIAL_NUMBER

walleye_recievers = merge(walleye_deploy, walleye_recovery,
                          by.x = c("GLATOS_PROJECT", "GLATOS_ARRAY", "STATION_NO",
                                    "CONSECUTIVE_DEPLOY_NO", "INS_SERIAL_NO"), 
                          by.y = c("GLATOS_PROJECT", "GLATOS_ARRAY", "STATION_NO", 
                                    "CONSECUTIVE_DEPLOY_NO", "INS_SERIAL_NO"), 
                          all.x=TRUE, all.y=TRUE) #keep all the info from each, merged using the above columns

View(walleye_recievers)

#need Tagging metadata too!

walleye_tag <- read_excel('inst_extdata_walleye_workbook.xlsm', sheet = 'Tagging')
View(walleye_tag)

#remember: we learned how to switch timezone of datetime columns above, 
# if that is something you need to do with your dataset!! 
  #hint: check GLATOS_TIMEZONE column to see if its what you want!

#the glatos R package (will be reviewed in the workshop tomorrow) can import your workbook in one step
#will format all datetimes to UTC, check for conflicts, join the deploy/recovery tabs etc.

library(glatos) #this won't work unless you happen to have this installed - just an teaser today, will be covered tomorrow
data <- read_glatos_workbook('inst_extdata_walleye_workbook.xlsm')
receivers <- data$receivers
animals <-  data$animals
~~~
{: .language-r}


