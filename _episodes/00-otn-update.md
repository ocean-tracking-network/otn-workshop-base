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

This set of workshop material is directed at researchers who are ready to begin the work of acoustic telemetry data analysis. The workshop begins without an introduction to the R coding language - some experience in R is expected.

If you'd like to refresh your R coding skills outside of this workshop curriculum, we recommend [Data Analysis and Visualization in R for Ecologists](https://datacarpentry.org/R-ecology-lesson/ "Website for R ecology lesson") as a good starting point. Much of this content is included in the first two lessons of this workshop.

##  Getting Started

Please follow the instrucions in the **"Setup"** tab along the top menu to install all required software, packages and data files. If you have questions or are running into errors please reach out to **OTNDC@DAL.CA** for support.


#### Intro to the `pathroutr` Package

The goal of `pathroutr` is to provide functions for re-routing paths that cross land around barrier polygons. The use-case in mind is movement paths derived from location estimates of marine animals. Due to error associated with these locations it is not uncommon for these tracks to cross land. The `pathroutr` package aims to provide a pragmatic and fast solution for re-routing these paths around land and along an efficient path. You can learn more [here](https://github.com/jmlondon/pathroutr)

Author: Dr. Josh M London ( josh.london@noaa.gov )
