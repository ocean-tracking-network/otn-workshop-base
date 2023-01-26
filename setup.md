---
title: Setup
---

## Requirements

You will requre 1) all the correct programs, 2) all the listed R packages 3) the dataset and code. Instructions for all these are below.


### Please see the attached document for program instructions: - [Program Install Instructions.docx](/Resources/install_instructions.docx)
-  R version: 3.6.x or newer (recommend 4.0.x) and RStudio
-  Rtools (Windows users only) and GDAL are only required for the Advanced Telemetry Workshop

Once all of the programs are installed, open RStudio and run the below package install scripts. It's best to run it line by line instead of all at once in case there are errors.

<b>Note:</b> When running through the installs, you may encounter a prompt asking you to upgrade dependent packages. Choosing Option `3: None`, works in most situations and will prevent upgrades of packages you weren't explicitly looking to upgrade.

### Beginner R Workshop Requirements

```r

# Tidyverse (data cleaning and arrangement)
install.packages('tidyverse')

# Lubridate - part of Tidyverse, improves the process of creating date objects
install.packages('lubridate')

# GGmap - complimentary to ggplot2, which is in the Tidyverse
install.packages('ggmap')

# Plotly - Interactive web-based data visualization
install.packages('plotly')

# ReadXL - reads Excel format
install.packages("readxl")

# Viridis - color scales in this package are easier to read by those with colorblindness, and print well in grey scale.
install.packages("viridis")
```

### Advanced Telemetry Workshop Requirements
<b>Note:</b> When running through the installs, you may encounter a prompt asking you to upgrade dependent packages. Choosing Option `3: None`, works in most situations and will prevent upgrades of packages you weren't explicitly looking to upgrade.

```r

# rgdal
install.packages('rgdal')
library(rgdal)
rgdal::getGDALVersionInfo()

# Tidyverse (data cleaning and arrangement)
install.packages('tidyverse')

# glatos - acoustic telemetry package that does filtering, vis, array simulation, etc.
install.packages('remotes')
library(remotes) 
remotes::install_github('ocean-tracking-network/glatos')

#Additional packages for mapping.
install.packages('stringr')
install.packages('mapview')
install.packages('spdplyr')

# Lubridate - part of Tidyverse, improves the process of creating date objects
install.packages('lubridate')

# GGmap - complimentary to ggplot2, which is in the Tidyverse
install.packages('ggmap')

#SP and Raster packages for mapping.
install.packages('sp')
install.packages('raster')

# Install actel
library(remotes)
remotes::install_github("hugomflavio/actel", build_opts = c("--no-resave-data", "--no-manual"), build_vignettes = TRUE)

# Install packages for building/displaying R Markdown
install.packages('rmarkdown')
install.packages('knitr', dependencies = TRUE)

# Install additonal packages for `remora` lesson
install.packages('readr')
install.packages('sf')
install.packages('stars')

# Install remora
install.packages('devtools')
library(devtools)
devtools::install_github('ocean-tracking-network/remora@get_data_qc', force=TRUE)

# Install packages for animating detection data
install.packages('remotes')
library(remotes) 
remotes::install_github("jmlondon/pathroutr")

install.packages('plotly')
install.packages('gganimate')
install.packages('ggspatial')


```

# Dataset and Code

<b>Once the above packages are installed</b>, you can download the datasets and code for this workshop from <b>[this link](https://github.com/ocean-tracking-network/otn-workshop-base/tree/master)</b>

1. Select the GREEN "Code" button at the top and choose "Download ZIP"
2. Unzip the folder and move to secure location on your computer (Documents, Desktop etc.)
3. Copy the folder's path and use it to set your working directly in R using `setwd('<path-to-folder>')`.

If you are familiar with Git and Github, feel free to clone this repository as you normally would, by running `git clone https://github.com/ocean-tracking-network/otn-workshop-base.git` in a terminal program and following from step `3` above.






{% include links.md %}
