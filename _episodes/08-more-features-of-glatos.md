---
title: More Features of GLATOS
teaching: 15
exercises: 0
questions:
    - "What other features does GLATOS offer?"
---

GLATOS has some more advanced analystic tools beyond filtering and creating events.

GLATOS can be used to get the residence index of your animals at all the different stations.
GLATOS offers 5 different methods for calculating Residence Index, here we will showcase 2 of those.
residence_index requires an events objects to create a residence_index, we will use the one
from the last lesson.

~~~
# Calc residence index using the Kessel method
rik_data <- glatos::residence_index(events, 
                                    calculation_method = 'kessel')
rik_data

# Calc residence index using the time interval method, interval set to 6 hours
rit_data <- glatos::residence_index(events, 
                                    calculation_method = 'time_interval', 
                                    time_interval_size = "6 hours")
rit_data
~~~
{: .language-r}

Both of these methods are similar and will almost always give different results, you can 
explore them all to see what method works best for your data.


GLATOS strives to be interoperable with other scientific R packages. Currently, we can 
crosswalk OTN data over to the package [VTrack](https://github.com/RossDwyer/VTrack). Here's an example:

~~~
?convert_otn_to_att

# FACT's tagging and deployment metadata sheet
tag_sheet_path <- 'TQCS_metadata_tagging.xlsx'
rcvr_sheet_path <- 'TEQ_Deployments.xlsx'

# Load the data from the tagging sheet and the receiver sheet
tags <- prepare_tag_sheet(tag_sheet_path, sheet=2)
receivers <- prepare_deploy_sheet(rcvr_sheet_path)

# Add columns missing from FACT extracts
detections_filtered['sensorvalue'] = NA
detections_filtered['sensorunit'] = NA

# Rename the station names in receivers to match station names in detections
receivers <- receivers %>% mutate(station=substring(station, 4))

ATTdata <- convert_otn_to_att(detections_filtered, tags, deploymentSheet = receivers)
~~~
{: .language-r}

And then you can use your data with the VTrack package. Here's an example of the Centers of Activity
function from VTrack.
~~~
coa <- VTrack::COA(ATTdata)
coa
~~~
{: .language-r}

GLATOS also includes tools for planning receiver arrays, simulating fish moving in an array, 
and some nice visualizations (which we will cover in the next episode).

