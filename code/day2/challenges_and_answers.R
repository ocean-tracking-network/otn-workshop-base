# Basic Visualization and Plotting: CHALLENGES ---------------------------------
# GLATOS workshop 2021-03-31
# Instructor: Ryan Gosse


# Challenge 1 ----
# Create a bubble plot of the station in Lake Erie only. Set the bounding box using the provided nw + se cordinates and 
# resize the points. As a bonus, add points for the other receivers in Lake Erie.
# Hint: ?detection_bubble_plot will help a lot


erie_arrays <-c("DRF", "DRL", "DRU", "MAU", "RAR", "SCL", "SCM", "TSR") # Given
nw <- c(43, -83.75) # Given
se <- c(41.25, -82) # Given


erie_detections <- detections_filtered %>% filter(glatos_array %in% erie_arrays)
erie_rcvrs <- receivers %>% filter(glatos_array %in% erie_arrays) # For bonus

erie_bubble <- detection_bubble_plot(erie_detections, 
                                     receiver_locs = erie_rcvrs, # For bonus
                                      location_col = 'station',
                                     background_ylim = c(se[1], nw[1]),
                                     background_xlim = c(nw[2], se[2]),
                                     symbol_radius = 0.75,
                                      out_file = 'erie_bubbles_by_stations.png')


