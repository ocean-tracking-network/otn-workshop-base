## Requirements------

### R version: 3.6.x or newer (recommend 4.0.x) and RStudio.
### Windows users: Please also download the Rtools version compatible with your R version https://cran.r-project.org/bin/windows/Rtools/history.html (not for MacOS)

# Advanced Telemetry Workshop ONLY: You must install also GDAL software, which can take a long time. See the extra setup document provided.

# Once R/RStudio is installed: open RStudio and run this install script. Please run it line-by-line instead of all at once in case there are errors.

#Note: When running through the installs, you may encounter a prompt asking you to upgrade dependent packages.
      #Choosing Option `3: None`, works in most situations and will prevent upgrades of packages you weren't explicitly looking to upgrade.



## Beginner R Workshop Requirements ----
# Tidyverse (data cleaning and arrangement)
install.packages('tidyverse')

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




## Advanced Telemetry Workshop Requirements ----
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
remotes::install_github("hugomflavio/actel", 
                        build_opts = c("--no-resave-data", "--no-manual"), build_vignettes = TRUE)

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
                                                            
                                                            

### Dataset and Code -----
# Once the packages are installed, you can download the datasets and code for this workshop from https://github.com/ocean-tracking-network/otn-workshop-base/tree/master.
# 1) Select the GREEN "code" button at the top and choose "Download ZIP"
# 2) Unzip the folder and move to secure location on your computer (Documents, Desktop etc.)
# 3) Copy the folder's path and use it to set your working directly in R using `setwd('<path-to-folder>')`.

# If you are familiar with Git and Github, feel free to clone this repository as you normally would,
# by running `git clone https://github.com/ocean-tracking-network/otn-workshop-base/tree/master.git` in a terminal program
# and following from step 3 above.
