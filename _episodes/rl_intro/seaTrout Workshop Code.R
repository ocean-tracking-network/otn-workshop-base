require(tidyverse)
require(marmap)
require(lubridate)
require(gganimate)
require(gifski)
require(rgeos)
require(argosfilter)
require(nlme)
require(igraph)
require(ggraph)
require(mgcv)

# seaTrout <- read.csv("ideasOTNtws2020code/rl_intro/seaTrout.csv")
load("seaTrout.rda")

str(seaTrout)
glimpse(seaTrout)

head(seaTrout)
seaTrout %>% head

## Chapter 1: base R and the tidyverse

# basic functions 1.1: subsetting

seaTrout[,c(6)]
seaTrout %>% select(6)

seaTrout[c(1:5),]
seaTrout %>% slice(1:5)

# basic functions 1.2: how many species do we have?

nrow(data.frame(unique(seaTrout$Species))) 

seaTrout %>% distinct(Species) %>% nrow

# basic function 1.3: format date times

as.POSIXct(seaTrout$DateTime)
seaTrout %>% mutate(DateTime=ymd_hms(DateTime))

# basic function 1.4: filtering

seaTrout[which(seaTrout$Species=="Trout"),]
seaTrout %>% filter(Species=="Trout")

# basic function 1.5: plotting

plot(seaTrout$lon, seaTrout$lat)
seaTrout %>% ggplot(aes(lon, lat))+geom_point()

# basic function 1.6: getting data summaries

tapply(seaTrout$lon, seaTrout$tag.ID, mean)
seaTrout %>% group_by(tag.ID) %>% summarise(mean=mean(lon))

## Chapter 2: expanding our ggplot capacity

# monthly longitudinal distribution of salmon smolts and sea trout

seaTrout %>% 
  group_by(m=month(DateTime), tag.ID, Species) %>% 
  summarise(mean=mean(lon)) %>% 
  ggplot(aes(m %>% factor, mean, colour=Species, fill=Species))+
  geom_point(size=3, position="jitter")+
  coord_flip()+
  scale_colour_manual(values=c("grey", "gold"))+
  scale_fill_manual(values=c("grey", "gold"))+
  geom_boxplot()+
  geom_violin()

seaTrout %>% 
  group_by(m=month(DateTime), tag.ID, Species) %>% 
  summarise(mean=mean(lon)) %>% 
  ggplot(aes(m, mean, colour=Species, fill=Species))+
  geom_point(size=3, position="jitter")+
  coord_flip()+
  scale_colour_manual(values=c("grey", "gold"))+
  scale_fill_manual(values=c("grey", "gold"))+
  geom_density2d(size=2, lty=1)

seaTrout %>% 
  group_by(m=month(DateTime), tag.ID, Species) %>% 
  summarise(mean=mean(lon)) %>% 
  ggplot(aes(m, mean))+
  stat_density_2d(aes(fill = stat(nlevel)), geom = "polygon")+
  #geom_point(size=3, position="jitter")+
  coord_flip()+
  facet_wrap(~Species)+
  scale_fill_viridis_c()

seaTrout %>% 
  ggplot(aes(lon, lat))+
  stat_density_2d(aes(fill = stat(nlevel)), geom = "polygon")+
  facet_wrap(~tag.ID)

## Chapter 3: Handling spatial objects in R

require(rgdal)
require(rgeos)
require(adehabitatHR)

stHR<-seaTrout %>% 
  group_by(tag.ID) %>% 
  summarise(n=n()) %>% 
  left_join(seaTrout) %>% 
  dplyr::select(tag.ID, lon, lat) %>% 
  filter(tag.ID=="A69-1601-30637" | tag.ID=="A69-1601-9614") %>% 
  droplevels() # essential

coordinates(stHR)<-~lon+lat
proj4string(stHR)<-CRS("+proj=utm +zone=33 +ellps=WGS84 +datum=WGS84 +units=m +no_defs") # set proj4string

#hr1<-kernelUD(stHR[,1], grid=10000, extent=1000)

#hr1<-getverticeshr(hr1)

#plot(hr1)

#image(hr1)

# we have coordinates in UTM, a metric based projection
# we want to work with latitude longitdude, so we must convert

st<-spTransform(seaTrout, CRS("+init=epsg:28992")) # error because needs to be a spatial object first!
coordinates(seaTrout)<-~lon+lat # make it a spatial object
proj4string(seaTrout)<-CRS("+proj=utm +zone=33 +ellps=WGS84 +datum=WGS84 +units=m +no_defs") # set proj4string
st<-spTransform(seaTrout, CRS("+proj=longlat +datum=WGS84")) #change proj4string
st<-data.frame(st)

# we want to see the study area, we can subset a world map or get a terrain/bathy map from marmap

x=.5
bgo <- getNOAA.bathy(lon1 = min(st$lon-x), lon2 = max(st$lon+x),
                     lat1 = min(st$lat-x), lat2 = max(st$lat+x), resolution = 1)
class(bgo); bgo %>% class
plot(bgo)
plot(bgo, col="royalblue")
autoplot(bgo)
bgo %>% fortify %>% as_tibble

bgo %>% 
  fortify %>% 
  ggplot(aes(x, y, fill=z))+
  geom_raster()+
  scale_fill_etopo()+
  labs(x="Longitude", y="Latitude", fill="Depth")+
  theme_classic()+
  theme(legend.position="top")+
  theme(legend.key.width = unit(5, "cm"))

bplot<-bgo %>%
  fortify %>% 
  ggplot(aes(x, y, z=z, fill=z))+
  geom_raster()+
  scale_fill_etopo()+
  labs(x="Longitude", y="Latitude", fill="Depth")+
  theme_classic()+
  theme(legend.position="top")+
  geom_point(data=st %>% 
               as_tibble() %>% 
               distinct(lon, lat),
             aes(lon, lat), inherit.aes=F, pch=21, fill="red", size=2)+
  theme(legend.key.width = unit(5, "cm"))

## Chapter 4: More tidy functions for your enjoyment

# some filtering and data processing 

st<-as_tibble(st)

st<-st %>% 
  mutate(dt=ymd_hms(DateTime)) %>% 
  dplyr::select(-1, -2, -DateTime) %>% 
  filter(month(dt)>5 & month(dt)<10) %>% 
  arrange(dt) %>% 
  group_by(tag.ID) %>% 
  mutate(llon=lag(lon), llat=lag(lat)) %>% 
  filter(lon!=lag(lon)) %>% 
  rowwise() %>% 
  filter(!is.na(llon)) %>%
  mutate(b=argosfilter::bearing(llat, lat, llon, lon)) %>% # use mutate to add bearings!
  mutate(dist=distance(llat, lat, llon, lon)) # use mutate to add distances!

# 4.1: Exploring our processed data

st %>% 
  group_by(tag.ID) %>% 
  mutate(cdist=cumsum(dist)) %>% 
  ggplot(aes(dt, cdist, colour=tag.ID))+geom_step()+facet_wrap(~Species)

st %>% 
  filter(dist>2) %>% 
  ggplot(aes(b, fill=Species))+
  #geom_histogram()+
  geom_density()+
  facet_wrap(~Species)+
  coord_polar()

## Chapter 5: Networks

# 5.1: Networks are just connections between nodes and we can draw a simple one

st %>% 
  group_by(Species, lon, lat, llon, llat) %>% 
  summarise(n=n()) %>% 
  ggplot(aes(x=llon, xend=lon, y=llat, yend=lat))+
  geom_segment()+geom_curve(colour="purple")+
  facet_wrap(~Species)+
  geom_point()

st %>% 
  group_by(Species, lon, lat, llon, llat) %>% 
  summarise(n=n()) %>% 
  ggplot(aes(x=llon, xend=lon, y=llat, yend=lat, size=n %>% log))+
  geom_segment()+geom_curve(colour="purple")+
  facet_wrap(~Species)+
  geom_point()

# 5.2: yes we can add this to our map!

bplot+
  geom_segment(data=st %>% 
                 group_by(Species, lon, lat, llon, llat) %>% 
                 summarise(n=n()),
               aes(x=llon, xend=lon, y=llat, yend=lat, size=n %>% log, alpha=n %>% log), inherit.aes=F)+
  facet_wrap(~Species)

require(igraph)
require(ggraph)
require(tidygraph)

# network by individual

nodes <- st %>%
  ungroup() %>% 
  distinct(Receiver) %>% 
  rowid_to_column("id")

rou <- st %>% 
  arrange(dt) %>% 
  group_by(tag.ID, Receiver, l=lag(Receiver, default=first(Receiver)), Species) %>% 
  summarise(weight=n()) %>% 
  filter(Receiver!=l) %>% 
  left_join(nodes) %>% 
  left_join(nodes, by=c("l"="Receiver")) %>% 
  rename(from=id.x, to=id.y)

rig <- tbl_graph(nodes = nodes, edges = rou, directed = F)

ggraph(rig)+
  geom_edge_link(aes(alpha=weight))+
  #geom_node_label(aes(label=id))+
  geom_node_point()+
  facet_wrap(~Species)+
  theme_classic()

degree(rig) %>% 
  as_tibble() %>% 
  bind_cols(nodes) %>% 
  left_join(st %>% group_by(Receiver) %>% summarise(n=n()), by="Receiver") %>% 
  rename(degree=value) %>% 
  ggplot(aes(degree, n))+
  #scale_y_log10()+
  geom_point()

# by individual

f1<-function(x){
  rou_id <- x %>% 
  arrange(dt) %>% 
  group_by(tag.ID, Receiver, tag.ID, l=lag(Receiver, default=first(Receiver)), Species) %>% 
  summarise(weight=n()) %>% 
  filter(Receiver!=l) %>% 
  left_join(nodes) %>% 
  left_join(nodes, by=c("l"="Receiver")) %>% 
  rename(from=id.x, to=id.y)

rig_id <- tbl_graph(nodes = nodes, edges = rou_id, directed = F)

diameter(rig_id)}

st %>% 
  split(.$tag.ID) %>% 
  purrr::map(f1) %>% 
  as_tibble() %>% 
  t() %>% 
  data.frame() %>% 
  rownames_to_column() %>% 
  as_tibble() %>% 
  rename(degree=".", tag.ID=rowname) %>% 
  left_join(st %>% distinct(tag.ID, Species, Length)) %>% 
  filter(!is.na(Species)) %>% 
  left_join(st %>% group_by(tag.ID, Receiver) %>% summarise(n=n())) %>% 
  group_by(tag.ID, Species, Length, degree) %>% summarise(n=n()) %>% 
  group_by(Species) %>% 
  mutate(Length=scale(Length)) %>% 
  ggplot(aes(Length, degree, colour=Species))+
  geom_point()+
  scale_x_log10()+
  scale_y_log10()

## Chapter 6: Animating plots

st1<-st %>% filter(tag.ID=="A69-1601-30617")

an1<-bgo %>%
  fortify %>% 
  ggplot(aes(x, y, fill=z))+
  geom_raster()+
  scale_fill_etopo()+
  labs(x="Longitude", y="Latitude", fill="Depth")+
  theme_classic()+
  theme(legend.key.width=unit(5, "cm"), legend.position="top")+
  theme(legend.position="top")+
  geom_point(data=st %>% 
               as_tibble() %>% 
               distinct(lon, lat),
             aes(lon, lat), inherit.aes=F, pch=21, fill="red", size=2)+
  geom_point(data=st1 %>% filter(tag.ID=="A69-1601-30617"),
             aes(lon, lat), inherit.aes=F, colour="purple", size=5)+
  transition_time(date(st1$dt))+
  labs(title = 'Date: {frame_time}')

animate(an1)

## Chapter 7: Some hypothesis tests

# H1: Trout moved farther seaward in the summer

st %>% 
  filter(Species=="Trout") %>% 
  ggplot(aes(dt, lon))+
  geom_point()

st %>% 
  ggplot(aes(dt %>% yday, lon))+
  geom_point()+
  geom_smooth(method="lm")

st %>% 
  filter(Species=="Trout") %>% 
  ggplot(aes(dt %>% yday, lon %>% log))+
  geom_point()+
  geom_smooth()

require(nlme)

m1<-lm(lon %>% log~as.numeric(dt), data=st)
summary(m1)
hist(resid(m1))
plot(resid(m1))

m2<-lme(lon~as.numeric(dt), random=~1|tag.ID, data=st)
hist(resid(m2))
plot(resid(m2))
summary(m2)

#m3<-gamm(lon~s(yday(dt)), correlation=corAR1(form=~1|yday(dt)), random=list(~1|tag.ID), data=st)
m3<-gamm(lon~s(yday(dt)), random=list(tag.ID=~1), data=st)

summary(m3)        
plot(m3$gam)


