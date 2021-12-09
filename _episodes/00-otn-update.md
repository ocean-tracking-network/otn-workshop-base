---
title: Background
teaching: 5
exercises: 0
questions:
    - "What is the Ocean Tracking Network?"
    - "How does your local telemetry network interact with OTN?"
	- "What methods of data analysis will be covered?"
---
## Intro to OTN

The Ocean Tracking Network (OTN) supports global telemetry research by providing training, equipment, and data infrastructure to our large network of partners. 

OTN and affiliated networks provide automated cross-referencing of your detection data with other tags in the system to help resolve "mystery detections" and provide detection data to taggers in other regions. OTN's Data Managers will also extensively quality-control your submitted metadata for errors to ensure the most accurate records possible are stored in the database. OTN's database and Data Portal website are excellent places to archive your datasets for future use and sharing with collaborators. We offer pathways to publish your datasets with OBIS, and via open data portals like ERDDAP, GeoServer etc. The data-product format returned by OTN is directly ingestible by analysis packages such as glatos and resonATe for ease of analysis. OTN offers support for the use of these packages and tools.

Learn more about OTN and our partners here [https://members.oceantrack.org/](https://members.oceantrack.org/).
Please contact **OTNDC@DAL.CA** if you are interested in connecting with your regional network and learning about their affiliation with OTN.

##  Intended Audience

This set of workshop material is directed at researchers who are ready to begin the work of acoustic telemetry data analysis. The first few lessons will begin with introductory R - no previous coding experince required. The workshop material progresses into more advanced techniques as we move along, beginning around lesson 8 "Introduction to Glatos". 

If you'd like to refresh your R coding skills outside of this workshop curriculum, we recommend [Data Analysis and Visualization in R for Ecologists](https://datacarpentry.org/R-ecology-lesson/ "Website for R ecology lesson") as a good starting point. Much of this content is included in the first two lessons of this workshop.

##  Getting Started

Please follow the instrucions in the **"Setup"** tab along the top menu to install all required software, packages and data files. If you have questions or are running into errors please reach out to **OTNDC@DAL.CA** for support.

##  Intro to Telemetry Data Analysis

OTN-affiliated telemetry networks all provide researchers with pre-formatted datasets, which are easily ingested into these data analysis tools.

Before diving in to a lot of analysis, it is important to take the time to clean and sort your dataset, taking the pre-formatted files and combining them in different ways, allowing you to analyse the data with different questions in mind.

There are multiple R packages necessary for efficient and thorough telemetry data analysis.  General packages that allow for data cleaning and arrangement, dataset manipulation and visualization, network analysis and temporo-spatial locating are used in conjuction with the telemetry analysis tool packages `VTtrack`, `actel` and `glatos`. 

There are many more useful packages covered in this workshop, but here are some highlights:


####  Intro to the `glatos` Package

`glatos` is an R package with functions useful to members of the Great Lakes Acoustic Telemetry Observation System (http://glatos.glos.us). Developed by Chris Holbrook of GLATOS, OTN helps to maintain and keep relevant. Functions may be generally useful for processing, analyzing, simulating, and visualizing acoustic telemetry data, but are not strictly limited to acoustic telemetry applications.  Tools included in this package facilitate false filtering of detections due to time between pings and disstance between pings.  There are tools to summarise and plot, including mapping of animal movement. Learn more [here](https://gitlab.oceantrack.org/GreatLakes/glatos/).

Maintainer: Dr. Chris Holbrook, ( cholbrook@usgs.gov )

####  Intro to the `VTrack` Package

This package was designed to facilitate the assimilation, analysis and synthesis of animal location and movement data collected by the VEMCO suite of acoustic transmitters and receivers. As well as database and geographic information capabilities the principal feature of [VTrack](https://cran.r-project.org/web/packages/VTrack/index.html) is the qualification and identification of ecologically relevant events from the acoustic detection and sensor data. This procedure condenses the acoustic detection database by orders of magnitude, greatly enhancing the synthesis of acoustic detection data. The development version of `VTrack` now houses a suit of functions called the 'Animal Tracking Toolbox' that helps users to follow a workflow to efficiently analyse acoustic telemetry data. You can find more information about the new functions in [this vignette](https://vinayudyawer.github.io/ATT/docs/ATT_Vignette.html). Learn more [here](https://github.com/RossDwyer/VTrack). 

Maintainer: Dr. Vinay Udyawer ( vinay.udyawer@gmail.com )

####  Intro to the `actel` Package

This package is designed for studies where animals tagged with acoustic tags are expected to move through receiver arrays. `actel` combines the advantages of automatic sorting and checking of animal movements with the possibility for user intervention on tags that deviate from expected behaviour. The three analysis functions: explore, migration and residency, allow the users to analyse their data in a systematic way, making it easy to compare results from different studies.

Author: Dr. Hugo Flavio, ( hflavio@wlu.ca )