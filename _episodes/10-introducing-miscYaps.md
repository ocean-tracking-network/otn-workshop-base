---
title: Introduction to the miscYAPS package
teaching: 0
exercises: 0
questions:
  - What is YAPS?
  - For what applications is YAPS well-suited?
  - How can I use the miscYAPS package to make working with YAPS easier? 
---

[YAPS](https://github.com/baktoft/yaps) (short for 'Yet Another Position Solver') is a package originally presented in a 2017 [paper](https://nature.com/articles/s41598-017-14278-z.pdf) by Baktoft, Gjelland, Økland & Thygesen. YAPS represents a way of positioning aquatic animals using statistical analysis (specifically, maximum likelihood analysis) in conjunction with time of arrival data, movement models, and state-space models. Likewise, [`miscYaps()`](https://github.com/robertlennox/miscYAPS) is a package developed by Dr. Robert Lennox to provide more intuitive wrappers for YAPS functions, to ease the analysis process. 

While we are still developing this lesson as templated text, as with the other lessons, we can provide the Powerpoint slides for the miscYaps talk given by Dr. Lennox at the CANSSI Early Career Researcher workshop. You can access the slides [here](../Resources/YAPS.pptx).

The following code is meant to be run alongside this powerpoint. 

~~~
remotes::install_github("robertlennox/miscYAPS")
require(yaps)
require(miscYAPS)

remotes::install_github("robertlennox/BTN")
require(BTN)

require(tidyverse)
require(lubridate)
require(data.table)

data(boats)
dets<-boats %>% pluck(1)
hydros<-dets %>%
  dplyr::distinct(serial, x, y, sync_tag=sync) %>%
  mutate(idx=c(1:nrow(.)), z=1)
detections<-dets %>%
  dplyr::filter(Spp=="Sync") %>%
  dplyr::select(ts, epo, frac, serial, tag)
ss_data<-boats %>% pluck(2) %>%
  dplyr::rename(ts=dt) %>%
  setDT

############
require(miscYAPS)
sync_model<-sync(hydros,
                 detections,
                 ss_data,
                 keep_rate=0.5,
                 HOW_THIN=100,
                 ss_data_what="data",
                 exclude_self_detections=T,
                 fixed=NULL)
plotSyncModelResids(sync_model)
sync_model<-sync(hydros,
                 detections,
                 ss_data,
                 keep_rate=0.5,
                 HOW_THIN=100,
                 ss_data_what="data",
                 exclude_self_detections=T,
                 fixed=c(1:9, 11:20))
fish_detections<-dets %>%
  dplyr::filter(Spp!="Sync") %>%
  mutate(tag=factor(tag)) %>%
  dplyr::select(ts, epo, frac, tag, serial)
tr<-swim_yaps(fish_detections, runs=3, rbi_min=60, rbi_max=120)
data(aur)
btnstorel <- BTN::storel 
raster::plot(btnstorel)
points(tr$x, tr$y, pch=1)
~~~
{: .language-r}