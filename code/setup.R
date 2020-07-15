## Requirements

### R version: 3.6.x or newer (recommend 4.0.x) and RStudio -----

#Open RStudio and run this install script. It's best to run it line by line instead of all at once in case there are errors.

#Note: When running through the installs, you may encounter a prompt asking you to upgrade dependent packages. 
      #Choosing Option `3: None`, works in most situations and will prevent upgrades of packages you weren't explicitly looking to upgrade.

# Tidyverse (data cleaning and arrangement)
install.packages('tidyverse')

# VTrack - Tools for Telemetry Analysis
install.packages("devtools")
library(devtools)
devtools::install_github("rossdwyer/VTrack")

# GLATOS - acoustic telemetry package that does filtering, vis, array simulation, etc.
install.packages('remotes')
library(remotes)
install_url("https://gitlab.oceantrack.org/GreatLakes/glatos/-/raw/spg-workshop-2020/glatos_0.4.2.1.tar.gz",
            build_opts = c("--no-resave-data", "--no-manual"))  

# Marmap - library that allows non-straight-line interpolation between two points.
# Useful for avoiding land masses when interpolating fish positions.
install.packages('marmap')

# Lubridate - part of Tidyverse, improves the process of creating date objects
install.packages('lubridate')

# gganimate and gifski help you animate ggplot objects
install.packages('gganimate')
install.packages('gifski')

# R language Bindings for the GEOS library, a pre-compiled, open source geometry engine for fast spatial calculation
install.packages('rgeos')
install.packages('rgdal')
install.packages('mapproj')

# Package for dealing with argos data, some useful functions for working with a series of geospatial data points
install.packages('argosfilter')

#SP and Raster packages for mapping.
install.packages('sp')
install.packages('raster')

#Install ffmpeg, which we use for the GLATOS-derived animations.
library(glatos) # once you have your GLATOS installed properly
install_ffmpeg()  

### Dataset and Code -----
# Once the packages are installed, you can download the datasets and code for this workshop from https://github.com/ocean-tracking-network/2020-07-16-OTNSPG-R-workshop/.

# 1) Select the GREEN "code" button at the top and choose "Download ZIP"
# 2) Unzip the folder and move to secure location on your computer (Documents, Desktop etc.)
# 3) Copy the folder's path and use it to set your working directly in R using `setwd('<path-to-folder>')`.

# If you are familiar with Git and Github, feel free to clone this repository as you normally would, 
# by running `git clone https://github.com/ocean-tracking-network/2020-07-16-OTNSPG-R-workshop.git` in a terminal program 
# and following from step 3 above.

