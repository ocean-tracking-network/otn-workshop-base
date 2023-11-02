---
title: Setup
---

## Requirements

You will requre 1) all the correct programs, 2) all the listed R packages 3) the dataset and code. Instructions for all these are below.


### Please see the attached document for program instructions: - [Program Install Instructions.docx](/Resources/install_instructions.docx)
-  R version: 3.6.x or newer (recommend 4.0.x) and RStudio
-  Rtools (Windows users only) and GDAL are only required for the Advanced Telemetry Workshop

> ## Extra steps to install glatos
> Due to recent issues with certain spatial packages being delisted from CRAN, you will need to install the archived version of `rgeos` before the package will work. You can get the most recent archive from [here](https://cran.r-project.org/src/contrib/Archive/rgeos/).
> At time of writing, 0.6-4 is the most recent. 
> You will then need to install the rgeos package, using the following code. 
> `install.packages("YOUR/PATH/TO/rgeos_0.6-4.tar.gz", repos = NULL, type = "source")`
{: .callout}

Once all of the programs are installed, open RStudio and run the below package install scripts. It's best to run it line by line instead of all at once in case there are errors.

<b>Note:</b> When running through the installs, you may encounter a prompt asking you to upgrade dependent packages. Choosing Option `3: None`, works in most situations and will prevent upgrades of packages you weren't explicitly looking to upgrade.

### Beginner R Workshop Requirements

```r

# Tidyverse (data cleaning and arrangement)
install.packages('tidyverse')

# GGmap - complimentary to ggplot2, which is in the Tidyverse
install.packages('ggmap')

# Plotly - Interactive web-based data visualization
install.packages('plotly')

# Lubridate - part of Tidyverse, improves the process of creating date objects
install.packages('lubridate')

# ReadXL - reads Excel format
install.packages("readxl")

# Viridis - color scales in this package are easier to read by those with colorblindness, and print well in grey scale.
install.packages("viridis")

# glatos - acoustic telemetry package that does filtering, vis, array simulation, etc.
install.packages('remotes')
library(remotes) 
remotes::install_github('ocean-tracking-network/glatos', build_vignettes = TRUE)

#Additional packages for mapping.
install.packages('mapview')
install.packages('spdplyr')
install.packages('geodata')

#SP and Raster packages for mapping.
install.packages('sp')
install.packages('raster')

# Install packages for building/displaying R Markdown
install.packages('rmarkdown')
install.packages('knitr', dependencies = TRUE)

# Install additonal packages for `remora` lesson
install.packages('readr')
install.packages('sf')
install.packages('stars')

# Install packages for animating detection data
install.packages('remotes')
library(remotes) 
remotes::install_github("jmlondon/pathroutr")

install.packages('gganimate')
install.packages('ggspatial')

#Install packages for YAPS lessons.
library(remotes)
remotes::install_github("robertlennox/miscYAPS")


```

# Dataset and Code

<b>Once the above packages are installed</b>, you can download the datasets and code for this workshop from <b>[this link](https://github.com/ocean-tracking-network/2023-canssi-ecr-workshop/tree/master)</b>

1. Select the GREEN "Code" button at the top and choose "Download ZIP"
2. Unzip the folder and move to secure location on your computer (Documents, Desktop etc.)
3. Copy the folder's path and use it to set your working directly in R using `setwd('<path-to-folder>')`.

If you are familiar with Git and Github, feel free to clone this repository as you normally would, by running `git clone https://github.com/ocean-tracking-network/otn-workshop-base.git` in a terminal program and following from step `3` above.






{% include links.md %}
