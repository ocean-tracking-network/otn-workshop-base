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
View(proj58_matched_full) #Check to make sure we already have our tag matches.

#Load in and join our array matches.

proj61_qual_2016 <- read_csv("Qualified_detecions_2016_2017/proj61_qualified_detections_2016.csv")
proj61_qual_2017 <- read_csv("Qualified_detecions_2016_2017/proj61_qualified_detections_2017.csv")
proj61_qual_16_17_full <- rbind(proj61_qual_2016, proj61_qual_2017) 

proj61_qual_16_17_full <- proj61_qual_16_17_full %>% slice(1:100000) #subset our example data for ease of analysis!

# lets import receiver station data from the network

#need Array metadata
#These are saved as XLS/XLSX files, so we need a different library to read them in.
library(readxl)

proj61_deploy <- read_excel("/Deploy_metadata_2016_2017/deploy_sercarray_proj61_2016_2017.xlsx", sheet = "Deployment", skip=3)
View(proj61_deploy)

#need Tag metadata

proj58_tag <- read_excel("/Tag_Metadata/Proj58_Metadata_cownoseray.xls", sheet = "Tag Metadata", skip=4) 
View(proj58_tag)

#remember: we learned how to switch timezone of datetime columns above, 
# if that is something you need to do with your dataset!! 
~~~
{: .language-r}


