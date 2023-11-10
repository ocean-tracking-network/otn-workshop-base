---
title: Introduction to Visualisation with GAMs
exercises: 0
questions:
  - What are GAMs?
  - How can I use GAMs to visualise my data? 
---

GAM is short for 'Generalized Additive Model', a type of statistical model. In this lesson, we will be using GAMs to visualise our data. 

While we are still developing this lesson as templated text like our other lessons, we can provide the Powerpoint slides for the GAMs talk given by Dr. Lennox at the CANSSI Early Career Researcher workshop. You can access the slides [here](../Resources/GAMs.pptx).

The following code is meant to be run alongside this presentation. 

~~~
require(BTN) # remotes::install_github("robertlennox/BTN")
require(tidyverse)
require(mgcv)
require(lubridate)
require(Thermimage)
require(lunar)
library(sf)
library(gratia)

theme_set<-theme_classic()+
  theme(text=element_text(size=20), axis.text=element_text(colour="black"))+
  theme(legend.position="top") # set a theme for ourselves

aur<-BTN::aurland %>% 
  st_transform(32633) %>% 
  slice(2) %>% 
  ggplot()+
  geom_sf()

#Load RData
load("YOUR/PATH/TO/data/otn/troutdata.RDS")

# first plot of the data

troutdata %>% 
  ggplot(aes(dt, Data, colour=Data))+
  geom_point()+
  theme_classic()+
  scale_colour_gradientn(colours=Thermimage::flirpal)

# mapping out the data

aur+
  geom_point(data=troutdata %>% 
               group_by(lon, lat) %>% 
               dplyr::summarise(m=mean(Data)),
             aes(lon, lat, colour=m))+
  scale_colour_gradientn(colours=Thermimage::flirpal)+
  theme(legend.position="top", legend.key.width=unit(3, "cm"))+
  theme_bw()

# 4. going for smooth
a<-troutdata %>% 
  mutate(h=hour(dt)) %>% 
  bam(Data ~ s(h, bs="cc", k=5), data=., method="fREML", discrete=T)

b<-troutdata %>% 
  mutate(h=hour(dt)) %>% 
  bam(Data ~ s(h, bs="tp", k=5), data=., , method="fREML", discrete=T)

c<-troutdata %>% 
  mutate(h=hour(dt)) %>% 
  bam(Data ~ h, data=., , method="fREML", discrete=T)

tibble(h=c(0:23)) %>% 
  mutate(circular=predict.gam(a, newdata=.)) %>% 
  mutate(thin_plate=predict.gam(b, newdata=.)) %>% 
  # mutate(v3=predict.gam(c, newdata=.)) %>% 
  gather(key, value, -h) %>% 
  ggplot(aes(h, value, colour=key))+
  geom_line(size=2)+
  theme_set+
  labs(x="Hour", y="Predicted Depth", colour="Model")+
  scale_y_reverse(limits=c(20, 0))+
  geom_hline(yintercept=0)+
  coord_polar()

#6. model fitting vehicle

m1<-troutdata %>% 
  mutate(h=hour(dt)) %>% 
  mutate(foid=factor(oid)) %>% 
  gam(Data ~ s(h, k=5)+s(foid, bs="re"), data=., method="REML")

m2<-troutdata %>% 
  mutate(h=hour(dt)) %>% 
  mutate(foid=factor(oid)) %>% 
  bam(Data ~ s(h, k=5)+s(foid, bs="re"), data=., method="fREML", discrete=T)

tibble(h=c(0:23)) %>% 
  mutate(foid=1) %>% 
  mutate(gam=predict.gam(m1, newdata=., type="response", exclude=c("s(foid)"))) %>% 
  mutate(bam=predict.gam(m2, newdata=., type="response", exclude=c("s(foid)"))) %>%
  mutate(i=gam-bam) %>% 
  gather(key, value, -h, -foid, -i) %>% 
  ggplot(aes(h, value, colour=i))+
  geom_line(size=2)+
  theme_set+
  facet_wrap(~key)+
  labs(x="Hour", y="Predicted temperature", colour="Difference between predictions")+
  theme(legend.key.width=unit(3, "cm"))+
  scale_colour_gradientn(colours=Thermimage::flirpal)


#8. check your knots

k1<-troutdata %>% 
  mutate(h=hour(dt)) %>% 
  bam(Data ~ s(h, bs="cc", k=5), data=., method="fREML", discrete=T)

k2<-troutdata %>% 
  mutate(h=hour(dt)) %>% 
  bam(Data ~ s(h, bs="cc", k=15), data=., , method="fREML", discrete=T)

tibble(h=c(0:23)) %>% 
  mutate("k=5"=predict.gam(k1, newdata=., type="response")) %>% 
  mutate("k=15"=predict.gam(k2, newdata=., type="response")) %>% 
  gather(key, value, -h) %>% 
  ggplot(aes(h, value/10, colour=key))+
  geom_line(size=2)+
  theme_set+
  labs(y="Temperature", x="Hour", colour="model")

#9. temporal dependency


t1<-troutdata %>% 
  mutate(h=hour(dt), yd=yday(dt), foid=factor(oid)) %>% 
  group_by(foid, dti=round_date(dt, "1 hour")) %>% 
  dplyr::filter(dt==min(dt)) %>% 
  bam(Data ~ s(h, k=5, bs="cc")+s(yd, k=10)+s(foid, bs="re"), data=., method="fREML", discrete=T)

t2<-troutdata %>% 
  mutate(h=hour(dt), yd=yday(dt), foid=factor(oid)) %>% 
  group_by(foid, dti=round_date(dt, "1 hour")) %>% 
  bam(Data ~ s(h, k=5, bs="cc")+s(yd, k=10)+s(foid, bs="re"), data=., method="fREML", discrete=T)

expand_grid(h=c(12),
            yd=c(32:60),
            foid=1) %>% 
  mutate(partial_series=predict.gam(t1, newdata=., type="response", exclude=c("s(foid)"))) %>% 
  mutate(full_series=predict.gam(t2, newdata=., type="response", exclude=c("s(foid)"))) %>% 
  gather(key, value, -h, -foid, -yd) %>% 
  ggplot(aes(yd, value, colour=key))+
  geom_point(data=troutdata %>% 
               mutate(h=hour(dt), yd=yday(dt), foid=factor(oid)),
             aes(yday(dt), Data), inherit.aes=F)+
  geom_path(size=2)+
  theme_set+
  labs(x="Date", y="Temperature", colour="Model")

# 10. spatial dependency

aur+
  geom_point(data=troutdata %>% 
               group_by(lon, lat) %>% 
               dplyr::summarise(m=mean(Data)),
             aes(lon, lat, colour=m))+
  scale_colour_gradientn(colours=Thermimage::flirpal)+
  theme(legend.position="top", legend.key.width=unit(3, "cm"))+
  theme_bw()+
  theme_set+
  theme(legend.position="top", legend.key.width=unit(3, "cm"))+
  labs(colour="mean temperature")

#11. interactions

mi<-troutdata %>% 
  mutate(h=hour(dt), yd=yday(dt), foid=factor(oid)) %>% 
  bam(Data ~ te(h, yd, bs=c("cc", "tp"), k=c(5, 10))+
        s(foid, bs="re"), data=., family=Gamma(link="log"), method="fREML", discrete=T)

ms<-troutdata %>% 
  mutate(h=hour(dt), yd=yday(dt), foid=factor(oid)) %>% 
  bam(Data ~ s(h, bs="cc", k=5)+
        s(yd, bs="tp", k=10)+
        s(foid, bs="re"), data=., family=Gamma(link="log"), method="fREML", discrete=T)


p1<-expand_grid(h=c(0:23), yd=c(182:212)) %>% 
  mutate(foid=1) %>% 
  mutate(value=predict.gam(ms, newdata=., type="response", exclude=c("s(foid)"))) %>% 
  mutate(i="Simple model, AIC=426 801") %>% 
  ggplot(aes(yd, h, fill=value))+
  geom_raster()+
  scale_fill_viridis_c()+theme_set+
  theme(legend.key.width=unit(3, "cm"))+
  labs(x="Date", y="Hour", fill="Predicted temperature")+
  facet_wrap(~i)

p2<-expand_grid(h=c(0:23), yd=c(182:212)) %>% 
  mutate(foid=1) %>% 
  mutate(value=predict.gam(mi, newdata=., type="response", exclude=c("s(foid)"))) %>% 
  mutate(i="Interaction model, AIC=425 805") %>% 
  ggplot(aes(yd, h, fill=value))+
  geom_raster()+
  scale_fill_viridis_c()+theme_set+
  theme(legend.key.width=unit(3, "cm"))+
  labs(x="Date", y="Hour", fill="Predicted temperature")+
  facet_wrap(~i)

AIC(mi, ms)
gridExtra::grid.arrange(p1, p2)

# is it the moon?

a<-expand_grid(h=c(0:23), yd=c(182:212)) %>% 
  mutate(foid=1) %>% 
  mutate(value=predict.gam(ms, newdata=., type="response", exclude=c("s(foid)"))) %>% 
  mutate(i="Simple model, AIC= -262 975") %>% 
  mutate(dt=ymd("2022-12-31")+days(yd)) %>% 
  mutate(l=lunar::lunar.illumination(dt)) %>% 
  ggplot(aes(yd, h, fill=value))+
  geom_raster()+
  scale_fill_viridis_c()+theme_set+
  theme(legend.key.width=unit(3, "cm"))+
  labs(x="Date", y="Hour", fill="Predicted temperature")+
  facet_wrap(~i)+
  geom_point(data=expand_grid(h=c(0:23), yd=c(182:212)) %>% 
               mutate(foid=1) %>% 
               mutate(value=predict.gam(ms, newdata=., type="response", exclude=c("s(foid)"))) %>% 
               mutate(i="Simple model, AIC= -262 975") %>% 
               mutate(dt=ymd("2022-12-31")+days(yd)) %>% 
               mutate(l=lunar::lunar.illumination(dt)) %>% 
               distinct(dt, yd, l),
             aes(yd, 10, size=l), inherit.aes=F, colour="white")

b<-expand_grid(h=c(0:23), yd=c(182:212)) %>% 
  mutate(foid=1) %>% 
  mutate(value=predict.gam(mi, newdata=., type="response", exclude=c("s(foid)"))) %>% 
  mutate(i="Interaction model, AIC=425 805") %>% 
  ggplot(aes(yd, h, fill=value))+
  geom_raster()+
  scale_fill_viridis_c()+theme_set+
  theme(legend.key.width=unit(3, "cm"))+
  labs(x="Date", y="Hour", fill="Predicted temperature")+
  facet_wrap(~i)+
  geom_point(data=expand_grid(h=c(0:23), yd=c(182:212)) %>% 
               mutate(foid=1) %>% 
               mutate(value=predict.gam(ms, newdata=., type="response", exclude=c("s(foid)"))) %>% 
               mutate(i="Simple model, AIC=426 801") %>% 
               mutate(dt=ymd("2022-12-31")+days(yd)) %>% 
               mutate(l=lunar::lunar.illumination(dt)) %>% 
               distinct(dt, yd, l),
             aes(yd, 10, size=l), inherit.aes=F, colour="white")


gridExtra::grid.arrange(a, b)


########### the worked example

troutdata %>% 
  mutate(lun=lunar::lunar.illumination(dt)) %>% 
  ggplot(aes(lun, Data))+
  geom_point()+
  theme_set+
  labs(x="Lunar illumination", y="Temperature")

troa<-troutdata %>% 
  mutate(foid=factor(oid)) %>% 
  mutate(lun=lunar::lunar.illumination(dt))

m0<-troa %>% 
  bam(Data ~ lun, data=., family=Gamma(link="log")) 

tibble(lun=seq(0,1, by=0.1)) %>% 
  mutate(p=predict.gam(m0, newdata=., type="response")) %>% 
  ggplot(aes(lun, p))+
  geom_point(data=troa, aes(lun, Data))+
  geom_line(colour="red")+
  theme_set+
  labs(x="Moonlight", y="Temperature")

m0<-troa %>% 
  bam(Data ~ lun+s(foid, bs="re"), data=., family=Gamma(link="log")) 

tibble(lun=seq(0,1, by=0.1)) %>% 
  mutate(foid=1) %>% 
  mutate(p=predict.gam(m0, newdata=., type="response", exclude=c("s(foid)"))) %>% 
  ggplot(aes(lun, p))+
  geom_point(data=troa, aes(lun, Data, colour=factor(foid)))+
  geom_line(colour="red")+
  theme_set+
  guides(colour=F)+
  labs(x="Moonlight", y="Temperature")

m0<-troa %>% 
  bam(Data ~ s(lun, k=7)+s(foid, bs="re"), data=., family=Gamma(link="log")) 

tibble(lun=seq(0,1, by=0.1)) %>% 
  mutate(foid=1) %>% 
  mutate(p=predict.gam(m0, newdata=., type="response", exclude=c("s(foid)"))) %>% 
  ggplot(aes(lun, p))+
  geom_point(data=troa, aes(lun, Data, colour=factor(foid)))+
  geom_line(colour="red")+
  theme_set+
  guides(colour=F)+
  labs(x="Moonlight", y="Temperature")

m01<-troa %>% 
  mutate(yd=yday(dt), h=hour(dt)) %>% 
  bam(Data ~ s(lun, k=7)+s(foid, bs="re")+
        s(h, bs="cc", k=5)+
        s(lon, lat, k=15), data=., family=Gamma(link="log")) 

BTN::aurland %>% 
  st_transform(32633) %>% 
  slice(2)

tibble(x=c(7.26, 7.32),
       y=c(60.85, 60.87)) %>% 
  st_as_sf(., coords=c("x", "y")) %>% 
  st_set_crs(4326) %>% 
  st_transform(32633)

sp<-expand_grid(lon=seq(80077, 83583, by=10),
                lat=seq(6770907, 6772740, by=10)) %>% 
  st_as_sf(., coords=c("lon", "lat")) %>% 
  st_set_crs(32633) %>% 
  st_intersection(BTN::aurland %>% 
                    slice(1) %>% 
                    st_transform(32633)) %>% 
  as(., "Spatial") %>% 
  as_tibble %>% 
  dplyr::rename(lon=coords.x1, lat=coords.x2) %>% 
  dplyr::select(lon, lat)

sp %>% 
  slice(1) %>% 
  expand_grid(., lun=seq(0, 1, by=0.1), h=c(0:23)) %>% 
  mutate(foid=1) %>% 
  mutate(value=predict.gam(m01, newdata=., exclude=c("s(foid)"))) %>% 
  ggplot(aes(h, lun, fill=value))+
  geom_raster()+
  scale_fill_gradientn(colours=Thermimage::flirpal)+
  theme_classic()+
  theme_set+
  theme(legend.key.width=unit(3, "cm"))+
  labs(x="Hour", y="Moonlight", fill="Predicted Temperature")

expand_grid(sp, lun=seq(0, 1, by=0.1), h=c(0, 12), yd=200) %>% 
  mutate(foid=1) %>% 
  mutate(p=predict.gam(m01, newdata=., type="response", exclude=c("s(foid)", "s(lon,lat)", "s(h)"))) %>% 
  ggplot(aes(lun, p))+
  geom_point(data=troa, aes(lun, Data, colour=factor(foid)))+
  geom_line()+
  theme_set+
  guides(colour=F)+
  labs(x="Moonlight", y="Temperature")


sp %>% 
  expand_grid(., lun=seq(0, 1, by=0.3)) %>% 
  mutate(foid=1, h=1) %>% 
  mutate(value=predict.gam(m01, newdata=., type="response", exclude=c("s(foid)"))) %>% 
  ggplot(aes(lon, lat, fill=value))+
  geom_raster()+
  scale_fill_gradientn(colours=Thermimage::flirpal)+
  theme_set+
  theme(legend.key.width=unit(3, "cm"))+
  labs(x="UTM (x)", y="UTM (y)", fill="Predicted Temperature")+
  coord_fixed(ratio=1)+
  facet_wrap(~lun)

gratia::draw(m01)

sp %>% 
  expand_grid(., lun=seq(0, 1, by=0.05), h=c(0:23)) %>% 
  mutate(foid=1) %>% 
  mutate(value=predict.gam(m01, newdata=., type="response", exclude=c("s(foid)", "s(lon,lat)"))) %>% 
  ggplot(aes(lun, value, colour=h))+
  geom_point()+
  theme_set+
  theme(legend.key.width=unit(3, "cm"))+
  scale_fill_gradientn(colours=Thermimage::flirpal)

coef(m01) %>% 
  data.frame %>% 
  rownames_to_column() %>% 
  as_tibble %>% 
  dplyr::filter(grepl("foid", rowname)) %>% 
  bind_cols(troa %>% distinct(foid)) %>% 
  left_join(troutdata %>% 
              group_by(oid) %>% 
              dplyr::summarise(m=mean(Data)) %>% 
              dplyr::rename(foid=oid) %>% 
              mutate(foid=factor(foid))) %>% 
  dplyr::rename(value=2) %>% 
  ggplot(aes(reorder(foid, value), value, colour=m))+
  geom_point()+
  coord_flip()+
  theme_set+
  labs(x="ID", y="Random intercept of temperature", size="Length (mm)", colour="True mean temperature")+
  scale_colour_viridis_c()
~~~
{: .language-r}