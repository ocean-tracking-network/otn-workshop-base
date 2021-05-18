---
title: Telemetry Reports - Imports
teaching: 10
exercises: 0
questions:
    - "What datasets do I need from the Network?"
    - "How do I import all the datasets?"
---

## Importing all the datasets
Now that we have an idea of what an exploratory workflow might look like with Tidyverse libraries like `dplyr` and `ggplot2`, let's look at how we might implement a common telemetry workflow using these tools. 

**Note to instructors: please choose the relevant Network below when teaching**

## ACT Node 

We are going to use OTN-style detection extracts for this lesson. If you're unfamiliar with detection extracts formats from OTN-style database nodes, see the documentation [here](https://members.oceantrack.org/data/otn-detection-extract-documentation-matched-to-animals). 

For the ACT Network you will receive Detection Extracts which include (1) Matched to Animals YYYY, (2) Detections Mapped to Other Trackers YYYY (also called Qualified) and (3) Unqualified Detections YYYY. In each case, the YYYY in the filename indicates the single year of data contained in the file. The types of detection extracts you receive will differ depending on the type of project you have regitered with the Network. ex: Tag-only projects will not receive Qualified and Unqualified detection extracts.

To illustrate the many meaningful summary reports which can be created use detection extracts, we will import an example of Matched and Qualified extracts.

First, we will comfirm we have our Tag Matches stored in a dataframe.
~~~
View(proj58_matched_full) #Check to make sure we already have our tag matches, from a previous episode

# if you do not have the variable created from a previous lesson, you can use the following code to re-create it:

proj58_matched_2016 <- read_csv("proj58_matched_detections_2016.csv") #Import 2016 detections
proj58_matched_2017 <- read_csv("proj58_matched_detections_2017.csv", guess_max = 41880) # Import 2017 detections
proj58_matched_full <- rbind(proj58_matched_2016, proj58_matched_2017) #Now join the two dataframes
# release records for animals often appear in >1 year, this will remove the duplicates
proj58_matched_full <- proj58_matched_full %>% distinct() # Use distinct to remove duplicates. 
~~~
{: .language-r}


Next, we will load in and join our Array matches.
~~~

proj61_qual_2016 <- read_csv("Qualified_detecions_2016_2017/proj61_qualified_detections_2016.csv")
proj61_qual_2017 <- read_csv("Qualified_detecions_2016_2017/proj61_qualified_detections_2017.csv")
proj61_qual_16_17_full <- rbind(proj61_qual_2016, proj61_qual_2017) 

proj61_qual_16_17_full <- proj61_qual_16_17_full %>% slice(1:100000) #subset our example data for ease of analysis!
~~~
{: .language-r}

To give meaning to these detections we should import our Instrument Deployment Metadata and Tagging Metadata as well. These are in the standard OTN-style templates which can be found [here](https://members.oceantrack.org/data/data-collection).
~~~
#These are saved as XLS/XLSX files, so we need a different library to read them in.
library(readxl)

# Deployment Metadata
proj61_deploy <- read_excel("/Deploy_metadata_2016_2017/deploy_sercarray_proj61_2016_2017.xlsx", sheet = "Deployment", skip=3)
View(proj61_deploy)

# Tag metadata
proj58_tag <- read_excel("/Tag_Metadata/Proj58_Metadata_cownoseray.xls", sheet = "Tag Metadata", skip=4) 
View(proj58_tag)

#remember: we learned how to switch timezone of datetime columns above, 
# if that is something you need to do with your dataset!
~~~
{: .language-r}

## FACT Node

We are going to use OTN-style detection extracts for this lesson. If you're unfamiliar with detection extracts formats from OTN-style database nodes, see the documentation [here](https://members.oceantrack.org/data/otn-detection-extract-documentation-matched-to-animals). 

For the FACT Network you will receive Detection Extracts which include (1) Matched to Animals YYYY, (2) Detections Mapped to Other Trackers - Extended YYYY (also called Qualified Extended) and (3) Unqualified Detections YYYY. In each case, the YYYY in the filename indicates the single year of data contained in the file and "extended" refers to the extra column provided to FACT Network members: "species detected". The types of detection extracts you receive will differ depending on the type of project you have regitered with the Network. If you have both an Array project and a Tag project you will likely need both sets of Detection Extracts.

To illustrate the many meaningful summary reports which can be created use detection extracts, we will import an example of Matched and Qualified extracts.

First, we will comfirm we have our Tag Matches stored in a dataframe.
~~~
View(tqcs_matched_10_11) #already have our Tag matches, from a previous lesson.

# if you do not have the variable created from a previous lesson, you can use the following code to re-create it:

tqcs_matched_2010 <- read_csv("data/tqcs_matched_detections_2010.csv", guess_max = 117172) #Import 2010 detections
tqcs_matched_2011 <- read_csv("data/tqcs_matched_detections_2011.csv", guess_max = 41880) #Import 2011 detections
tqcs_matched_10_11_full <- rbind(tqcs_matched_2010, tqcs_matched_2011) #Now join the two dataframes
# release records for animals often appear in >1 year, this will remove the duplicates
tqcs_matched_10_11_full <- tqcs_matched_10_11_full %>% distinct() # Use distinct to remove duplicates. 
tqcs_matched_10_11 <- tqcs_matched_10_11_full %>% slice(1:100000) # subset our example data to help this workshop run smoother!
~~~
{: .language-r}

Next, we will load in and join our Array matches.

~~~
teq_qual_2010 <- read_csv("data/teq_qualified_detections_2010_ish.csv")
teq_qual_2011 <- read_csv("data/teq_qualified_detections_2011_ish.csv")
teq_qual_10_11_full <- rbind(teq_qual_2010, teq_qual_2011) 

teq_qual_10_11 <- teq_qual_10_11_full %>% slice(1:100000) #subset our example data for ease of analysis!
~~~
{: .language-r}

To give meaning to these detections we should import our Instrument Deployment Metadata and Tagging Metadata as well. These are in the standard VEMBU/FACT-style templates which can be found [here](https://secoora.org/fact/projects-species/projects/acoustic-telemetry-resources/).

~~~
# Array metadata

teq_deploy <- read.csv("data/TEQ_Deployments_201001_201201.csv")
View(teq_deploy)

# Tag metadata

tqcs_tag <- read.csv("data/TQCS_metadata_tagging.csv") 
View(tqcs_tag)

#remember: we learned how to switch timezone of datetime columns above, if that is something you need to do with your dataset!!
~~~
{: .language-r}


## GLATOS Network

For the GLATOS Network you will receive Detection Extracts which include all the Tag matches for your animals. These can be used to create many meaningful summary reports.

First, we will comfirm we have our Tag Matches stored in a dataframe.

~~~
View(lamprey_dets) #already have our Lamprey tag matches

# if you do not have the variable created from a previous lesson, you can use the following code to re-create it:

lamprey_dets <- read_csv("inst_extdata_lamprey_detections.csv", guess_max = 3102)
~~~
{: .language-r}

Next, we will load in and join our Walleye matches.

~~~
walleye_dets <- read_csv("inst_extdata_walleye_detections.csv", guess_max = 9595) #remember guess_max from prev section!

# lets join these two detection files together!

all_dets <- rbind(lamprey_dets, walleye_dets)
~~~
{: .language-r}

To give meaning to these detections we should import our GLATOS Workbook. These are in the standard GLATOS-style template which can be found [here](https://glatos.glos.us/portal).

~~~
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

#remember: we learned how to switch timezone of datetime columns above, 
# if that is something you need to do with your dataset!! 
  #hint: check GLATOS_TIMEZONE column to see if its what you want!
~~~
{: .language-r}

The `glatos` R package (which will be introduced in future lessons) can import your Workbook in one step! The function will format all datetimes to UTC, check for conflicts, join the deploy/recovery tabs etc. This package is beyond the scope of this lesson, but is incredibly useful for GLATOS Network members. Below is some example code:

~~~
# this won't work unless you happen to have this installed - just an teaser today, will be covered tomorrow
library(glatos) 
data <- read_glatos_workbook('inst_extdata_walleye_workbook.xlsm')
receivers <- data$receivers
animals <-  data$animals
~~~
{: .language-r}

Finally, we can import the station locations for the entire GLATOS Network, to help give context to our detections which may have occured on parter arrays.
~~~
glatos_receivers <- read_csv("inst_extdata_sample_receivers.csv")
View(glatos_receivers)
~~~
{: .language-r}


