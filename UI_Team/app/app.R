library(shiny)
library(ggplot2)
library(dplyr)
library(tidyr)
library(readr)
library(purrr)
library(tibble)
library(stringr)
library(forcats)
library(plotly)
library(httr)
library(jsonlite)
library(RColorBrewer)
library(bslib)

library(shinyjs)
library(DT)


flask_url <- "http://flask:5000/"


#Chatbot function
source("chatbot.R",local=T)
productlist <- c('Watchman', 'Atriclip', 'Lariat')

ui <- fluidPage(
  useShinyjs(),
  theme = bs_theme(version = 4, booswatch = "minty"),
  #Application title
  titlePanel("AI Assistant for Medical Sales Representative"),
  #Sidebar for information of product
  sidebarLayout(
    sidebarPanel(
      tags$br(selectInput("ChooseProd",label = "Learn More About", choices = productlist)),
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
      ),
    )
  ),
  #Take file input to process new documents, users should specify the device that they're looking for
  fluidRow(
    column(6, "Upload a pdf file containing information about your medical device:",
           fluidRow(column(5, fileInput("file1",label="", accept=".pdf")))),
    column(3, textInput("device_in_file", "Find out more about other devices! If there are multiple devices, please separate by comma without spaces.", placeholder = "E.g. Device A,Device B"))
  ),
  
  hr(),
  
  fluidRow(
  column(3, style = "position: absolute; bottom: 5px; left: 0 ",
         div(actionButton("JarvikBtn", "Jarvik", style="font-size:30px",icon('question-sign',lib = "glyphicon")), 
             style="right:10px; bottom: 5px; position: absolute"),
    
    hidden(wellPanel(id = 'chat', style="bottom:70px",
    tags$div(id = 'placeholder', style = "max-height: 200px; overflow: auto"),
    hidden(tags$div(id = "else", hidden(actionButton("elseBtn","Show me something else", class="btn btn-sm")),
                    actionButton("switchBtn","Search for another device",  class="btn btn-sm"))),
    div(id = 'txt_label', textInput('txt', h4("How can I help you?") , placeholder = "Enter your questions"),
    actionButton('insertBtn', 'Insert'),
    actionButton('removeBtn', 'Remove'),
    actionButton('clearBtn', 'Clear')),
    tags$br()
    )),
  offset = 9
  )
  )
)

server <- function(input,output,session){
  bs_themer()
  #adds input device names to select input
  observeEvent(input$device_in_file, {
    new_productlist = c(productlist,str_split(input$device_in_file,',')[[1]])
    updateSelectInput(session,"ChooseProd",choices= new_productlist)
    productlist = new_productlist
  })
  
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
  
  # Jarvik Chatbot
  inserted <- c()
  device <- c()
  ques <- c()
  btn <- c()
  
  observeEvent(input$JarvikBtn, {
    toggle("chat")
    if(input$JarvikBtn%%2){
      if (length(btn)==0){btn <<- input$JarvikBtn}
      else btn <<- btn+1
      id <- paste0('txt', btn)
      insertUI(
        selector = '#placeholder',
        ui = tags$div(
            tags$hr(),
            tags$p(renderText({paste("Jarvik: ","Hello, I am Jarvik! Your AI Assistant!")})),
            tags$p(renderText({paste("Jarvik: ","What device are you looking for?")})),
            id = id
            )
      )
      inserted <<- c(id, inserted)
      }
  })
  
  
  observeEvent(input$insertBtn, {
    if (length(btn)==0){btn <<- input$insertBtn}
    else btn <<- btn+1
    id <- paste0('txt', btn)
    text <- input$txt
    insertUI(
      selector = '#placeholder',
      ui = tags$div(
        tags$b(paste('You: ', text)),
        if(text!=""){
        # check whether previous device inserted
        if (length(device) == 0) {found <- check_device(text, productlist)}
        else {found <- -1} # Have revious device
        
        if(found==0){
          # Not valid device
          tags$div(tags$p(renderText({paste("Jarvik: ", "Sorry I do not have this device infomation!")})),
                    tags$p(renderText({paste("Jarvik: Please search for another device by typing below!")})),
                            tags$hr())
          }else if(found != -1){
            # A valid device found 
            device <<- c(text, device)
            tags$p(renderText({paste("Jarvik: ", "Great! What is your question?")}))
        }else{
          # Text is the question (after searching for a valid device)
          ques <<- c(text, ques)
          answer <- build_chatbot(device, ques, find=1)
          tags$p(renderText({paste("Jarvik:[", device[length(device)], "]", answer)}))
        }
        }else{
          tags$p(renderText({paste("Jarvik: ", "I am not sure I understand you fully")}))
        },
        id = id
      )
    )
    if(text!="" && found == -1){
      show("else")
      show("elseBtn")
    }else{hide("else")}
    
    updateTextInput(session, "txt",  value= "")
    inserted <<- c(id, inserted)
  })
  
  observeEvent(input$elseBtn,{
    btn <<- btn + 1
    id <- paste0('txt', btn)
    answer <- build_chatbot(device, ques[1], input$elseBtn+1)
    insertUI(
      selector = '#placeholder',
      ## wrap element in a div with id for ease of removal
      ui = tags$div(
        tags$b(paste('You: ','Show me something else about "', ques[1], '"')),
        if (answer != -1){tags$p(renderText({paste("Jarvik:[", device[length(device)], "]", answer)}))}
        else {tags$div(tags$p(renderText({paste("Jarvik:[", device[length(device)], "]", 
                                       "Sorry, I cannot come up with other answers.")})),
                    tags$p(renderText({paste("Jarvik:[", device[length(device)], "]", 
                                                       "Please ask for another question!")})) 
                      )},
        id = id
      )
    )
    if (answer == -1){
      hide("elseBtn")
      #updateActionButton(session, "elseBtn", label = "Another Question")
      ques <<- c()
    }else{ques <<- c(ques[1], ques)}
    inserted <<- c(id, inserted)
  })
  
  observeEvent(input$switchBtn,{
    btn <<- btn + 1
    id <- paste0('txt', btn)
    insertUI(
      selector = '#placeholder',
      ui = tags$div(
        tags$hr(),
        tags$b(renderText({paste("Jarvik: ","What device are you looking for?")})),
        tags$br(),
        device <<- c(),
        ques <<- c(),
        id = id
      )
    )
    hide("else")
    inserted <<- c(id, inserted)
  })
  
  observeEvent(input$removeBtn, {
    btn <<- btn + 1
    id <- paste0('txt', btn)
    removeUI(
      selector = paste0('#', inserted[1]),
    )
    hide("else")
    inserted <<- inserted[-1]
    
    insertUI(
      selector = paste0('#', inserted[1]),
      ui = tags$div(
        if (length(ques) == 0){
          device <<- c()
          tags$b(renderText({paste("Jarvik: ","Please type the device you want to search for")}))
          tags$br()
        }else{
          ques <<- ques[-1]
          tags$b(renderText({paste('Jarvik: ', 'You can also ask questions about "', 
                                   device[length(device)], '"')}))
          tags$br()
        }
      )
    )
  })
  
  observeEvent(input$clearBtn, {
    removeUI(
      selector = paste0('#', inserted),
      multiple = T
    )
    hide("else")
    inserted <<- c()
    device <<- c()
    ques <<- c()
  })
  
}

#Run the application
shinyApp(ui = ui, server = server)
