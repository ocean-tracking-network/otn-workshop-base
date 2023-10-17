---
title: Telemetry Reports - Imports
teaching: 10
exercises: 0
questions:
    - "What datasets do I need from the Network?"
    - "How do I import all the datasets?"
---


## Importing all the datasets
Let's look at how we might implement a common telemetry workflow using Tidyverse libraries like `dplyr` and `ggplot2`. 

We are going to use OTN-style detection extracts for this lesson. If you're unfamiliar with detection extracts formats from OTN-style database nodes, see the documentation [here](https://members.oceantrack.org/data/otn-detection-extract-documentation-matched-to-animals). 

For OTN you will receive Detection Extracts which include (1) Matched to Animals YYYY, (2) Detections Mapped to Other Trackers YYYY (also called Qualified) and (3) Unqualified Detections YYYY. In each case, the YYYY in the filename indicates the single year of data contained in the file. The types of detection extracts you receive will differ depending on the type of project you have regitered with the Network. ex: Tag-only projects will not receive Qualified and Unqualified detection extracts.

To illustrate the many meaningful summary reports which can be created use detection extracts, we will import an example of Matched and Qualified extracts.

First, we will comfirm we have our Tag Matches stored in a dataframe.
~~~
library(tidyverse)# really neat collection of packages! https://www.tidyverse.org/
library(lubridate)
library(readxl)
library(viridis)
library(plotly)
library(ggmap)

setwd('YOUR/PATH/TO/data/otn') #set folder you're going to work in
getwd() #check working directory


nsbs_matched_2021 <- read_csv("nsbs_matched_detections_2021.zip") #Import 2021 detections
nsbs_matched_2022 <- read_csv("nsbs_matched_detections_2022.zip") # Import 2022 detections
nsbs_matched_full <- rbind(nsbs_matched_2021, nsbs_matched_2022) #Now join the two dataframes
# release records for animals often appear in >1 year, this will remove the duplicates
nsbs_matched_full <- nsbs_matched_full %>% distinct() # Use distinct to remove duplicates.  
~~~
{: .language-r}


Next, we will load in and join our Array matches. Ensure you replace the filepath to show the files as they appear in your working directory, if needed.
~~~

hfx_qual_2021 <- read_csv("hfx_qualified_detections_2021_workshop.csv")
hfx_qual_2022 <- read_csv("hfx_qualified_detections_2022_workshop.csv") 
hfx_qual_21_22_full <- rbind(hfx_qual_2021, hfx_qual_2022) 
~~~
{: .language-r}

To give meaning to these detections we should import our Instrument Deployment Metadata and Tagging Metadata as well. These are in the standard OTN-style templates which can be found [here](https://members.oceantrack.org/data/data-collection).
~~~
#These are saved as XLS/XLSX files, so we need a different library to read them in. 

# Deployment Metadata
hfx_deploy <- read_excel("hfx_sample_deploy_metadata_export.xlsx", skip=3) #can also do argument "sheet = XXX" if needed
View(hfx_deploy)

# Tag metadata
nsbs_tag <- read_excel("nsbs_sample_tag_metadata_export.xlsx")
View(nsbs_tag)

#keep in mind the timezone of the columns
~~~
{: .language-r}

