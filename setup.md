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
```

Once the packages are installed, create a new directory and set your working directory using `setwd('<path-to-folder>')`

If you don't want to live code along, we have provided R Markdown files for each lesson which can be downloaded [here](rmarkdown.zip), but we *highly* recommend coding along with the rest of the workshop.



