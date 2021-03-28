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
crosswalk GLATOS data over to the package [VTrack](https://github.com/RossDwyer/VTrack). Here's an example:

~~~
?convert_glatos_to_att

# The receiver metadata for the walleye dataset
rec_file <- system.file("extdata", 
                        "sample_receivers.csv", package = "glatos")

receivers <- read_glatos_receivers(rec_file)

ATTdata <- convert_glatos_to_att(detections_filtered, receivers)

# ATT is split into 3 objects, we can view them like this
ATTdata$Tag.Detections
ATTdata$Tag.Metadata
ATTdata$Station.Information
~~~
{: .language-r}

And then you can use your data with the VTrack package. You can call its abacusPlot function to generate an abacus plot:
~~~
# Now that we have an ATT dataframe, we can use it in VTrack functions:

# Abacus plot:
VTrack::abacusPlot(ATTdata)
~~~
{: .language-r}

To use the spacial features of VTrack, we have to give the ATT object a coordinate system to use.
~~~
# If you're going to do spatial things in ATT:
library(rgdal)
# Tell the ATT dataframe its coordinates are in decimal lat/lon
proj <- CRS("+init=epsg:4326")
attr(ATTdata, "CRS") <-proj
~~~
{: .language-r}

Here's an example of the Centers of Activity function from VTrack.
~~~
?COA
coa <- VTrack::COA(ATTdata)
coa
~~~
{: .language-r}

GLATOS also includes tools for planning receiver arrays, simulating fish moving in an array, 
and some nice visualizations (which we will cover in the next episode).

