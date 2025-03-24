library(shiny)
library(ggplot2)
library(dplyr)
library(akima)
library(raster)
library(sf)
library(rnaturalearth)
library(RColorBrewer)

# Load your custom functions from an external file
source("heatmapp_functions.R")  # Ensure this file contains your functions including main()

ui <- fluidPage(
  titlePanel("Heatmapp v 1.0"),
  
  fluidRow(
    column(3,  # Inputs on the left (3/12 of the width)
           fileInput("file", "Upload a file", accept = c(".txt", ".csv", ".tsv")),
           numericInput("bin_number", "Enter the number of bins:", value = 20, min = 1, step = 1),
           actionButton("process", "Process Data"),
           sliderInput("slider", "Select a time range:", min = 1, max = 1, value = 1, step = 1),
           textOutput("displayValue")
    ),
    
    column(9,  # Map on the right (9/12 of the width)
           plotOutput("outputPlot", height = "600px")  # Increase map size if needed
    )
  )
)

server <- function(input, output, session) {
  
  results <- reactiveVal(NULL)  # Store results to update reactively
  
  observeEvent(input$process, {
    req(input$file, input$bin_number)  # Ensure both file and bin number are provided
    
    # Read the uploaded file
    distance_df <- read.table(input$file$datapath, sep = "\t", header = TRUE, stringsAsFactors = FALSE)
    
    # Run the main function with user input
    res <- main(distance_df, input$bin_number)
    results(res)
    
    # Update the slider range based on available time ranges
    updateSliderInput(session, "slider",
                      min = 1,
                      max = length(res$ranges),
                      value = 1,
                      step = 1)
  })
  
  output$displayValue <- renderText({
    req(results(), results()$ranges)  # Ensure results exist
    
    if (is.null(input$slider) || input$slider > length(results()$ranges)) {
      return("Select a valid time range")
    }
    
    range <- results()$ranges[[input$slider]]
    
    if (identical(range, "Modern")) {
      "Modern samples"
    } else {
      paste("From", range[1], "years ago to", range[2], "years ago")
    }
  })
  
  output$outputPlot <- renderPlot({
    req(results())  # Ensure results exist
    
    results()$plots[[input$slider]]
  })
}

shinyApp(ui, server)