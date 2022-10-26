
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
library(bslib)

renv::init(bare=TRUE)
renv:snapshot()
renv:status()

flask_url <- "http://flask:5000/"

ui <- fluidPage(
  
  theme = bs_theme(version = 4, booswatch = "minty"),
  
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
        id="inTabset", type = 'hidden',
        tabPanel("Description",
                 uiOutput("help_text"),
                 plotOutput("distPlot")),
        
        tabPanel("Benefits",
                 tableOutput("newTable"))
      )
      
    )
    
  )
  
)

server <- function(input,output, session){
  #action button for "What?" -> Description Tab
  observeEvent(input$what.button, {
    updateTabsetPanel(session, "inTabset",
                      selected = "Description")
  })
  
  #action button for "Why?" -> Benefits Tab  
  observeEvent(input$why.button, {
    updateTabsetPanel(session, "inTabset",
                      selected = "Benefits")
  })
  
  
  output$help_text <- renderUI({
    HTML("<b> Click 'Show plot' to show the plot. </b>")
  })
  
  #output Description for Watchman
  output$distPlot <- renderPlot({
    plot_data()
  })
  
  #Output Benefits for Watchman
  output$newTable <- renderTable({
    data()
  })
  
}


#Run the application
shinyApp(ui = ui, server = server)
