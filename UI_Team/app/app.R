#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#
install.packages("shiny")
install.packages("tidyverse")
install.packages("plotly")
install.packages("httr")
install.packages("jsonlite")
install.packages("RColorBrewer")
install.packages("renv")
library(shiny)
library(tidyverse)
library(plotly)
library(httr)
library(jsonlite)
library(RColorBrewer)
library(renv)
renv::init()
renv:snapshot()
renv:status()

flask_url <- "http://flask:5000/"

ui <- fluidPage(
  
  #Application title
  titlePanel("AI Assistant for Medical Sales Representative"),
  
  #Sidebar for information of product
  sidebarLayout(
    sidebarPanel(
      tags$br(actionButton(inputId="what.button",label="What?",icon=NULL)),
      tags$br(),
      tags$br(actionButton(inputId="why.button",label="Why?",icon=NULL)),
      tags$br(),
      tags$br(actionButton(inputId="how.button",label="How?",icon=NULL)),
      tags$br(),
      tags$br(actionButton(inputId="stats.button",label="Statistics",icon=NULL)),
      width = 2
    ),
    
    mainPanel(
      tabsetPanel(
        tabPanel(
          "Description",
          uiOutput("help_text"),
          plotOutput("distPlot")
        ),
        
      )
      
    )
    
  )
  
)

server <- function(input,output){
  
  output$help_text <- renderUI({
    HTML("<b> Click 'Show plot' to show the plot. </b>")
  })
  
  output$distPlot <- renderPlot({
    plot_data()
  })
  
  
  
}


#Run the application
shinyApp(ui = ui, server = server)
