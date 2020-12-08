library(glatos)
library(dplyr)

# Detection Data
det_file_name <- 'tqcs_matched_detections.csv'


# Save our detections file data into a dataframe called detections
detections <- read_otn_detections(det_file=det_file_name)

# View first 2 rows of output
head(detections, 2)

## Filtering False Detections ####
detections_filtered <- false_detections(detections, tf=3600, show_plot=TRUE)

detections_filtered <- detections_filtered[detections_filtered$passed_filter == 1,]
nrow(detections_filtered)

# Reduce Detections to Detection Events ####
events <- detection_events(detections_filtered, 
                           location_col = 'station', # combines events across different receivers in a single array
                           time_sep=432000)

# keep detections, but add a 'group' column for each event group
detections_w_events <- detection_events(detections_filtered, 
                                        location_col = 'station', # combines events across different receivers in a single array
                                        time_sep=432000, condense=FALSE)

# Visualizing Data - Abacus Plots ####
# ?glatos::abacus_plot
# customizable version of the standard VUE-derived abacus plots

abacus_plot(detections_w_events, 
            location_col='station', 
            main='TQCS Detections By Station') # can use plot() variables here, they get passed thru to plot()

# pick a single fish to plot
abacus_plot(detections_filtered[detections_filtered$animal_id== "TQCS-1049258-2008-02-14",],
            location_col='station',
            main="TQCS-1049258-2008-02-14 Detections By Station")

library(raster)
library(sp)

USA <- getData('GADM', country="USA", level=1)
FL <- Canada[Canada$NAME_1=="Florida",]

# Bubble Plots for Spatial Distribution of Fish ####
# bubble variable gets the summary data that was created to make the plot
detections_filtered
bubble <- detection_bubble_plot(detections_filtered, 
                                out_file = '../tqcs_bubble.png',
                                location_col = 'station',
                                map = FL,
                                col_grad=c('white', 'green'),
                                background_xlim = c(-81, -80),
                                background_ylim = c(26, 28))
