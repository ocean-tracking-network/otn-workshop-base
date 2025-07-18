---
title: Setup
---

## Requirements

You will requre 1) all the correct programs, 2) all the listed R packages 3) the dataset and code. Instructions for all these are below.

You can also use the following checklist to keep track of your progress. If you have trouble with any step of the process,
do not hesitate to contact us and we will help you solve it in advance of the workshop. 

**Software & Environment**
- [] I have installed the latest version of R and RStudio. Note: Older versions may cause compatibility issues with some packages.
- [] (Windows Users Only) I have installed RTools. Note: RTools is required to build and install certain R packages on Windows.
- [] (Windows Users Only) I have confirmed that RTools is correctly added to my system's environment PATH variable. Note: This ensures RStudio can properly find and run them.
- [] I have run the setup script from this page, and installed all relevant packages

**Files & Resources**
- [] I have downloaded the correct data files and scripts from the official source. Note: for this workshop, the official source is [here](LINK TO REPOSITORY)
- [] The downloaded files are unzipped and saved in my RStudio instance's current working directory. Note: You can use `getwd()` in the RStudio console to check your current working directory and make sure your files are there. 

**Network & Access (Only relevant if you are attending a workshop)**
- [] I have connected to the correct Wi-Fi network. Note: Wi-Fi credentials are printed on the back of your name card

### Please see the attached document for program instructions: - [Program Install Instructions.docx](/Resources/install_instructions.docx)
-  R version: 3.6.x or newer (recommend 4.0.x) and RStudio
-  Rtools (Windows users only) and GDAL are only required for the Advanced Telemetry Workshop

Once all of the programs are installed, open RStudio and run the below package install scripts. It's best to run it line by line instead of all at once in case there are errors.

<b>Note:</b> When running through the installs, you may encounter a prompt asking you to upgrade dependent packages. Choosing Option `3: None`, works in most situations and will prevent upgrades of packages you weren't explicitly looking to upgrade.

### Beginner R Workshop Requirements

```r

# Tidyverse (data cleaning and arrangement)
install.packages('tidyverse')

# Nanoparquet (importing parquet files to dataframes)
install.packages('nanoparquet')

# Lubridate - part of Tidyverse, improves the process of creating date objects
install.packages('lubridate')

# GGmap - complimentary to ggplot2, which is in the Tidyverse
install.packages('ggmap')
#This is a temporarily available API key you can use for plotting StadiaMaps in ggmap this workshop. You SHOULD NOT rely on this key being available after the workshop.
ggmap::register_stadiamaps("b01d1235-69e8-49ea-b3bd-c35b42424b00")

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
devtools::install_github('ocean-tracking-network/remora@workshop_ready', force=TRUE)

# Install packages for animating detection data
install.packages('remotes')
library(remotes) 
remotes::install_github("jmlondon/pathroutr")

install.packages('plotly')
install.packages('gganimate')
install.packages('ggspatial')


```

# Dataset and Code

If you are unfamiliar with using Git to download and access code, it is possible to instead download the code as a ZIP archive. This will prevent you from using any of Git's version control functionality, but you will otherwise have all of the code available once the archive is extracted. The steps are as follows:

1. Navigate in your browser to the [repository for this workshop](Link to the workshop repository)
2. Select the GREEN "Code" button at the top and choose "Download ZIP"
3. Unzip the folder and move to secure location on your computer (Documents, Desktop etc.)
4. Copy the folder's path and use it to set your working directly in R using `setwd('<path-to-folder>')`.

If you are familiar with Git and Github, feel free to clone this repository as you normally would, by running `git clone https://github.com/ocean-tracking-network/otn-workshop-base.git` in a terminal program and following from step `3` above.






{% include links.md %}
