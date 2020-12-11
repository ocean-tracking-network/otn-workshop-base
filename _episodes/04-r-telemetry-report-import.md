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
~~~
{: .language-r}


