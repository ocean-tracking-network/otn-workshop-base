# Basic Visualization and Plotting: CHALLENGES ---------------------------------
# GLATOS workshop 2021-03-31
# Instructor: Ryan Gosse



# Challenge 1 ----
# Create a bubble plot of that bay we zoomed in earlier. Set the bounding box using the provided nw + se cordinates, change the colour scale and 
# resize the points to be smaller. As a bonus, add points for the other receivers that don't have any detections.
# Hint: ?detection_bubble_plot will help a lot
# Here's some code to get you started

nw <- c(38.75, -76.75) # given
se <- c(39, -76.25) # given

deploys <- read_otn_deployments('matos_FineToShare_stations_receivers_202104091205.csv') # For bonus

bubble_challenge <- detection_bubble_plot(detections_filtered,
                                      background_ylim = c(nw[1], se[1]),
                                      background_xlim = c(nw[2], se[2]),
                                      map = MD,
                                      symbol_radius = 0.75,
                                      location_col = 'station',
                                      col_grad = c('white', 'green'),
                                      receiver_locs = deploys, # For bonus
                                      out_file = 'act_bubbles_challenge.png')


