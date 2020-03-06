---
title: Setup
---

## Requirements

### R version: 3.6.x or newer and RStudio

Open RStudio and run this install script. It's best to run it line by line instead of all at once in case there are errors.

<b>Note:</b> When running through the installs, you may encounter a prompt asking you to upgrade dependent packages. Choosing Option `3: None`, works in most situations and will prevent upgrades of packages you weren't explicitly looking to upgrade.
```r


install.packages("devtools")

# Tidyverse (data cleaning and arrangement)
install.packages('tidyverse')

# Mapping spatial data
install.packages('plotly')

# VTrack - Tools for Telemetry Analysis
devtools::install_github("rossdwyer/VTrack")

# GLATOS - acoustic telemetry package that does filtering, vis, array simulation, etc.
install.packages('remotes')
library(remotes)
install_url("https://gitlab.oceantrack.org/GreatLakes/glatos/repository/master/archive.zip",
            build_opts = c("--no-resave-data", "--no-manual"))  

# Marmap - library that allows non-straight-line interpolation between two points.
# Useful for avoiding land masses when interpolating fish positions.
install.packages(marmap)
# Lubridate - part of Tidyverse, improves the process of creating date objects
install.packages(lubridate)
# gganimate and gifski help you animate ggplot objects
install.packages(gganimate)
install.packages(gifski)

# R language Bindings for the GEOS library, a pre-compiled, open source geometry engine for fast spatial calculation
install.packages(rgeos)
install.packages(mapproj)

# Package for dealing with argos data, some useful functions for working with a series of geospatial data points
install.packages(argosfilter)            
```

Once the packages are installed, set your working directory using `setwd('<path-to-folder>')`

We have provided R Markdown files for each lesson which can be downloaded [here](rmarkdown.zip).
