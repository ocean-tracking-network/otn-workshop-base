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
