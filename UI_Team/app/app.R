library(shiny)
library(tidyverse)
library(plotly)
library(httr)
library(jsonlite)
library(RColorBrewer)
library(bslib)

library(shinyjs)
library(DT)


flask_url <- "http://flask:5000/"
model <- jsonlite::fromJSON("test_model.js")

# If no input from user, use default model
default_model <- c(
  "Very interesting",
  "I am not sure I understand you fully",
  "What does that suggest to you?",
  "Please continue",
  "Go on",
  "Do you feel strongly about discussing such things?"
)


# Function to generate response
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
  ),
  
  fluidRow(
    column(3, style = "position: absolute; bottom: 5px; left: 0 ",
           wellPanel(
             tags$div(id = 'placeholder', style = "max-height: 200px; overflow: auto"),
             div(id = 'txt_label', textInput('txt', 'How can I help you?'),
                 actionButton('insertBtn', 'Insert'),
                 actionButton('removeBtn', 'Remove'),
                 actionButton('clearBtn', 'Clear')),
             tags$style(type="text/css", "#txt_label {font-weight: bold; font-size: 25px}")
           ),
           offset = 9
    )
  )
)

server <- function(input,output,session){
  
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
  
  # Chatbot
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
    updateTextInput(session, "txt", value = "")
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
      selector = paste0('#', inserted),
      multiple = T
    )
    inserted <<- c()
  })
  
}

#Run the application
shinyApp(ui = ui, server = server)
