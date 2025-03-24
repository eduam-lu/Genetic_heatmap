#!usr/bin/env R

#Load libraries
library(ggplot2)
library(readxl)
library(akima)
library(raster)
library(sf)
library(rnaturalearth)
library(dplyr)
library(RColorBrewer)  

# Distances dataframe processor
dist_df_processor <- function(distance_df) {
  # Ensure that latitude and longitude are numeric
  distance_df$Lat. <- as.numeric(distance_df$Lat.)
  distance_df$Long. <- as.numeric(distance_df$Long.)
  
  # Drop NA values in Long., Lat., and DST
  distance_df <- distance_df[complete.cases(distance_df$Long., distance_df$Lat., distance_df$DST), ]
  
  # Split ancient and modern dataframes
  modern_distances <- distance_df[distance_df$Years.BP == 0, ]
  ancient_distances <- distance_df[distance_df$Years.BP != 0, ]
  
  # Return a list with modern and ancient data
  return(list(modern = modern_distances, ancient = ancient_distances))
}

# Parse years into bins
year_parser <- function(ancient_df, bin_num) {
  # Load and sort the years from the dataframe
  years <- sort(ancient_df$Years.BP, decreasing = FALSE)
  
  # Compute bin size (may not divide evenly)
  bin_size <- round(length(years) / bin_num)
  
  # Parse the years into bins
  index <- 1
  final_ranges <- list()  
  
  for (i in 1:bin_num) {  
    # Use the sorted years vector
    start_year <- years[index]
    # Ensure that we don't exceed the vector length
    end_index <- min(index + bin_size - 1, length(years))
    end_year <- years[end_index]
    final_ranges[[i]] <- c(start_year, end_year)
    index <- index + bin_size
  }
  
  # Manually adjust the last bin's end year to the maximum value
  final_ranges[[bin_num]][2] <- years[length(years)]
  
  return(list(ranges = final_ranges, size = bin_size))
}

# Plot for modern data
modern_plotter <- function(df, bin_size) {
  # Determine sample size based on bin_size
  x <- round((bin_size + 100) / 5)
  
  # Sample individuals stratified by genetic distance (DST)
  reduced_df <- df %>%
    mutate(rango = cut(DST, 
                       breaks = seq(min(DST), max(DST), length.out = 6), 
                       include.lowest = TRUE)) %>%
    group_by(rango) %>%
    sample_n(size = min(x, n()), replace = FALSE) %>%  
    ungroup()
  
  # Plot using the main plotter function
  p <- main_plotter(reduced_df)
  return(p)
}

# Plot for ancient data
ancient_plotter <- function(ancient_df, bin_num) {
  parsing <- year_parser(ancient_df, bin_num)
  year_ranges <- parsing$ranges
  bin_size <- parsing$size
  
  ancient_plots <- list()
  
  for (i in seq_along(year_ranges)) {
    # Subset ancient_df based on the current year range
    df_to_plot <- ancient_df[ancient_df$Years.BP >= year_ranges[[i]][1] & 
                               ancient_df$Years.BP <= year_ranges[[i]][2], ]
    
    # Generate and store the plot
    ancient_plots[[i]] <- main_plotter(df_to_plot)  
  }
  
  return(ancient_plots)
}

# Main plotting function: creates the map and overlays data
main_plotter <- function(df) {
  # Get world map data for background
  world <- ggplot2::map_data("world")
  
  # Interpolate the scattered data (Long., Lat., DST) onto a regular grid.
  interp_result <- with(df, akima::interp(x = Long., y = Lat., z = DST,
                                          duplicate = "mean", linear = TRUE))
  
  # Convert interpolation result to a data frame.
  grid_data <- data.frame(expand.grid(x = interp_result$x, y = interp_result$y),
                          genetic_distance = as.vector(interp_result$z))
  
  # Create the combined plot
  ggplot() +
    # Raster layer of interpolated genetic distances
    geom_raster(data = grid_data %>% filter(!is.na(genetic_distance)), 
                aes(x = x, y = y, fill = genetic_distance), interpolate = TRUE) +
    # Color scale for the raster
    scale_fill_gradientn(colours = rev(brewer.pal(7, "Spectral"))) +
    # Overlay world boundaries
    geom_polygon(data = world, aes(x = long, y = lat, group = group),
                 fill = NA, color = "black") +
    # Plot the original data points
    geom_point(data = df, aes(x = Long., y = Lat., color = DST), 
               size = 2, alpha = 0.7) +
    # Color scale for the points
    scale_color_gradientn(colours = rev(brewer.pal(7, "Spectral")), guide = "none") +
    # Maintain map proportions
    coord_fixed(ratio = 1.5) +
    theme_minimal() +
    labs(fill = "Genetic Distance", color = "Genetic Distance",
         x = "Longitude", y = "Latitude")
}

# Main function to process data and generate plots
main <- function(df, bin_num) {
  # Process the dataframe into modern and ancient subsets
  result_dfs <- dist_df_processor(df)
  ancient_df <- result_dfs$ancient
  modern_df <- result_dfs$modern
  
  # Generate plots for ancient data
  ancient_plots <- ancient_plotter(ancient_df, bin_num)
  
  # Parse years to obtain bin size for modern sampling
  parsing <- year_parser(ancient_df, bin_num)
  year_ranges <- parsing$ranges
  bin_size <- parsing$size
  
  # Generate the modern plot
  modern_plot <- modern_plotter(modern_df, bin_size)
  
  # Combine the modern plot with the ancient plots
  final_plots <- c(list(modern_plot), ancient_plots)
  year_ranges <- c(list("Modern"), year_ranges)
  # Return both the plots and the year ranges used for binning
  return(list(plots = final_plots, ranges = year_ranges))
}