# !/usr/bin/env Rscript
library(ggplot2)
library(readxl)
library(akima)
library(raster)
library(sf)
library(rnaturalearth)
library(dplyr)


### Load the data from an excel sheet into a dataframe
df <- read_excel("Data/GeneticDistances.xlsx", sheet = 1)

### Transform into a smaller df with only lat, long and genetic distance
data <- data.frame(
  lon = df$Long ,
  lat = df$Lat ,    
  genetic_distance = df$Dist
)

### Function for laying the genetic distances as points
plot_worldmap_points <- function(df) {
  # This plot overlays all teh data points over the world map
  #Colours them according to genetic distance
  
  world <- ggplot2::map_data("world")  # Load world map
  
  ggplot2::ggplot(data = df, ggplot2::aes(x = lon, y = lat, color = genetic_distance)) +
    ggplot2::geom_polygon(data = world, ggplot2::aes(x = long, y = lat, group = group),
                          color = "black", fill = "white") +
    ggplot2::geom_point(size = 2, alpha = 0.7) +  # Plot points with color based on Dist
    ggplot2::scale_color_gradientn(colours = rev(RColorBrewer::brewer.pal(7, "Spectral"))) +
    ggplot2::coord_fixed(ratio = 1.4) +  # Keep map proportions correct
    ggplot2::theme_minimal() +
    ggplot2::theme(legend.position = "right")
}
plot_worldmap_points(data)

plot_worldmap_gradient <- function(df) {
  # This function takes genetic distances in different locations and generates a heatmap
  # by rastering the values
  
  # Get world map data for the background
  world <- ggplot2::map_data("world")
  
  # Interpolate the scattered data (long, lat, Dist) onto a regular grid.
  # 'akima::interp' creates a grid with estimated values.
  interp_result <- with(df, akima::interp(x = lon, y = lat, z = genetic_distance,
                                          duplicate = "mean", linear = TRUE))
  
  # Convert the interpolation output to a data frame.
  # expand.grid() creates all combinations of x and y grid values.
  grid_data <- data.frame(expand.grid(x = interp_result$x, y = interp_result$y),
                          genetic_distance = as.vector(interp_result$z))
  
  # Set a threshold for the genetic distance
  
  # Create the plot
  ggplot() +
    # Plot the interpolated grid as a raster layer, but only show values above the threshold.
    geom_raster(data = grid_data %>% dplyr::filter(!is.na(genetic_distance)), 
                aes(x = x, y = y, fill = genetic_distance), interpolate = TRUE) +
    
    # Define the color scale for the genetic distance, starting from the threshold value.
    scale_fill_gradientn(colours = rev(RColorBrewer::brewer.pal(7, "Spectral"))) +
    
    # Overlay the world boundaries
    geom_polygon(data = world, aes(x = long, y = lat, group = group),
                 fill = NA, color = "black") +
    
    # Ensure correct map proportions with a ratio of 0.5
    coord_fixed(ratio = 1.5) +
    
    # A minimal theme for a clean look
    theme_minimal() +
    
    # Add labels for clarity
    labs(fill = "Genetic Distance", x = "Longitude", y = "Latitude")
}

plot_worldmap_gradient(data)




