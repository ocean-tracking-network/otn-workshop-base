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

# OTN's tagging metadata sheet
tag_sheet_path <- system.file("extdata", "otn_nsbs_tag_metadata.xls",
                        package = "glatos")
# detections
det_file_name <- system.file("extdata", "blue_shark_detections.csv",
                             package = "glatos")
# Receiver Location
rec_file_name <- system.file("extdata", "hfx_deployments.csv",
                             package = "glatos")

detections <- read_otn_detections(det_file=det_file_name)
receivers <- read_otn_deployments(rec_file_name)
# Load the data from the tagging sheet
# the 5 means start on line 5, and the 2 means use sheet 2
tags <- prepare_tag_sheet(tag_sheet_path, 5, 2)


ATTdata <- convert_otn_to_att(detections, tags, deploymentObj = receivers)
~~~
{: .language-r}

And then you can use your data with the VTrack package.

GLATOS also includes tools for planning receiver arrays, simulating fish moving in an array, 
and some nice visualizations (which we will cover in the next episode).

