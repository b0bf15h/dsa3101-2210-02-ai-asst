library(shiny)
library(tidyverse)
library(plotly)
library(httr)
library(jsonlite)
library(RColorBrewer)
library(shinyalert)

flask_url <- "http://flask:5000/"

ui <- fluidPage(
  
  #Application title
  titlePanel("AI Assistant for Medical Sales Representative"),
  useShinyalert(),  # Set up shinyalert
  actionButton("chatbox", "Chat Box"),
  
  tags$br(),
  tags$br(),
  tags$br(),
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

  ),
  fluidRow(tabsetPanel(id='tabs', 
                       tabPanel("Tab1",
                                div(id = "form", 
                                    textInput("A", label="Product A *" ),
                                    selectInput("userId", label="UserId", choices = c("UserA", "UserB", "UserC"),selected = "UserA"), 
                                    textInput("B", label = "Product B"), 
                                    selectInput("feature", label="Feature", choices = c("A", "B", "C"))
                                ),
                                actionButton("add", "Add")
                       ), 
                       tabPanel("Tab2", 
                                tabPanel("View", 
                                         conditionalPanel("input.add != 0", 
                                                          DTOutput("DT2"), hr(), downloadButton('downloadData', 'Download'))
                                )
                       )
  )
  )
  
)
  
server <- function(input,output,session){
  
  output$help_text <- renderUI({
    HTML("<b> Click 'Show plot' to show the plot. </b>")
  })
  
  output$distPlot <- renderPlot({
    plot_data()
  })
  
  observeEvent(input$chatbox, {
    # Show a modal when the button is pressed
    shinyalert(
      title = "Type your questions", type = "input",
      callbackR = function(value) {
        shinyalert(paste("Your question is ", value))
      }
    )
  })
  
  store <- reactiveValues()
  
  observeEvent(input$add,{
    new_entry <- data.frame(Target_Product=input$A, User=input$userId
                            , Compared_With= input$B
                            , Question=input$feature)
    
    if("value" %in% names(store)){
      store$value<-bind_rows(store$value, new_entry)
    } else {
      store$value<-new_entry
    }
    # If you want to reset the field values after each entry use the following two lines
    for(textInputId in c("A", "B")) updateTextInput(session, textInputId, value = "")
    updateSelectInput(session, "userId", selected = "UserA")
    updateSelectInput(session, "feature", selected = "A")
  })
  output$DT2 <- renderDT({
    store$value
  })

  
}
  
  
#Run the application
shinyApp(ui = ui, server = server)
