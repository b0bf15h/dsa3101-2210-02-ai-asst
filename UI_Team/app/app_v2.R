library(shiny)
library(tidyverse)
library(plotly)
library(httr)
library(jsonlite)
library(RColorBrewer)
library(shinyalert)
library(DT)
#library(rjson)

flask_url <- "http://flask:5000/"
model <- jsonlite::fromJSON("test_model.json")

default_model <- c(
  "Very interesting",
  "I am not sure I understand you fully",
  "What does that suggest to you?",
  "Please continue",
  "Go on",
  "Do you feel strongly about discussing such things?"
)

Chatbot <- function(input) {
  # match keywords from model
  pos <- which(lapply(paste0("(.*)?", names(model), "(.*)?"), grep, x = input, ignore.case = TRUE) == 1)
  output <- unlist(model[pos])
  if (length(pos) == 0) {
    # choose default answer randomly if no keyword is found
    output <- sample(default_model, 1)
  } else {
    # choose applicable answer randomly
    pos <- ifelse(length (pos) > 1, sample(pos, 1), pos)
    output <- sample(output, 1)
    names(output) <- NULL
    # customize answer
    tmp <- regexec(names(model)[pos], input, ignore.case = TRUE)[[1]]
    end_phrase <- substr(input, start = attr(tmp, "match.length") + as.numeric(tmp) + 1, stop = nchar(input))
    end_phrase <- trimws(end_phrase, which = "right", whitespace = "[?!.]")
    output <- sub("\\$", end_phrase, output)
  }
  output
}

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
  ),
  fluidRow(
  column(3, style = "position: absolute; bottom: 0; left: 0; max-height: 300px; overflow-y:scroll",
         wellPanel(
    textInput('txt', 'How can I help you?'),
    actionButton('insertBtn', 'Insert'),
    actionButton('removeBtn', 'Remove'),
    actionButton('clearBtn', 'Clear'),
    tags$div(id = 'placeholder')
    ),
  offset = 9
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
  
  inserted <- c()
  
  observeEvent(input$insertBtn, {
    btn <- input$insertBtn
    id <- paste0('txt', btn)
    value <- input$txt
    insertUI(
      selector = '#placeholder',
      ## wrap element in a div with id for ease of removal
      ui = tags$div(
        # tags$p(paste('Number: ', btn)),
        tags$p(paste('You: ', value)),
        tags$p(renderText({paste("Chatbot: ", Chatbot(value))})),
        id = id
      )
    )
    inserted <<- c(id, inserted)
  })
  
  observeEvent(input$removeBtn, {
    removeUI(
      ## pass in appropriate div id
      selector = paste0('#', inserted[1])
    )
    inserted <<- inserted[-1]
  })
  
  observeEvent(input$clearBtn, {
    removeUI(
      ## pass in appropriate div id
      # selector = paste0('div:has(> #', inserted,')')
      selector = paste0('#', inserted),
      multiple = T
    )
    inserted <<- c()
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
