library(shiny)
library(purrr)
library(stringr)
library(httr)
library(jsonlite)
library(bslib)
library(shinyjs)
library(DT)
library(shinydashboard)
library(shinyBS)
library(dplyr)
library(shinyalert)

# use chatbot program in the same directory
source("chatbot.R",local=T)
# pre-defined product list
productlist <- c('Watchman', 'Atriclip', 'Lariat', '')

upload_endpoint <- "http://flask:5000/upload"

# arbitrarily decided on 40MB as max-upload size, changeable
options(shiny.maxRequestSize=40*1024^2) 

# ---------------------------- HELPER FUNCTIONS ----------------------------

# code for mapping enter key to clicking on the insert button
jscode <- '
$(function() {
  var $els = $("[data-proxy-click]");
  $.each(
    $els,
    function(idx, el) {
      var $el = $(el);
      var $proxy = $("#" + $el.data("proxyClick"));
      $el.keydown(function (e) {
        if (e.keyCode == 13) {
          $proxy.click();
        }
      });
    }
  );
});
'

customSentence1 <- function(numItems,type) {
  paste("Feedback & Suggestions")
}

customSentence2 <- function(numItems,type) {
  paste("The accuracy of our responses will be further improved when the document store is populated with more data.")
}

dropdownMenuCustom <- function (..., type = c("messages", "notifications", "tasks"), 
                                badgeStatus = "primary", icon = NULL, .list = NULL, customSentence = customSentence) 
{
  type <- match.arg(type)
  if (!is.null(badgeStatus)) shinydashboard:::validateStatus(badgeStatus)
  items <- c(list(...), .list)
  lapply(items, shinydashboard:::tagAssert, type = "li")
  dropdownClass <- paste0("dropdown ", type, "-menu")
  if (is.null(icon)) {
    icon <- switch(type, messages = shiny::icon("envelope", verify_fa = F), 
                   notifications = shiny::icon("warning", verify_fa = F), tasks = shiny::icon("tasks"))
  }
  numItems <- length(items)
  if (is.null(badgeStatus)) {
    badge <- NULL
  }
  else {
    badge <- tags$span(class = paste0("label label-", badgeStatus), 
                       numItems)
  }
  tags$li(
    class = dropdownClass, 
    a(
      href = "#", 
      class = "dropdown-toggle", 
      `data-toggle` = "dropdown", 
      icon, 
      badge
    ), 
    tags$ul(
      class = "dropdown-menu", 
      tags$li(
        class = "header", 
        customSentence(numItems, type)
      ), 
      tags$li(
        tags$ul(class = "menu", items)
      )
    )
  )
}


# BOX FUNCTION

upload_box <- box(title = "Upload Data of New Product",
                  status = "info", solidHeader = TRUE, width = 12,
                  
                  fluidRow(
                    column(10, h4(icon("upload"),"Upload a PDF file containing information about your medical device"))),
                  fluidRow(
                    # file name input, need to label the file upload with device name
                    column(6, textInput("device_in_file",
                                        "Input the name of your product",
                                        placeholder = "Name of product",
                                        width = "95%")),
                    column(6, fileInput("file1",
                                        label = "Select a file",
                                        accept = ".pdf",
                                        width = "95%"))),
                  fluidRow( align = "center",
                    column(12, actionButton("submit",
                                           label = "Click here to submit!",
                                           width = '900px'))))

upload_box2 <- box(title = "Upload Data of Existing Product",
                  status = "primary", solidHeader = TRUE, width = 12,
                  
                  fluidRow(
                    column(10, h4(icon("upload"),"Upload a PDF file containing information about current medical device"))),
                  fluidRow(
                    # file name input, need to label the file upload with device name
                    column(6, selectInput("ChooseProd",
                                          label = "Select Existing Product",
                                          choices = productlist,
                                          width = "95%")),
                    column(6, fileInput("file2",
                                        label = "Select a file",
                                        accept = ".pdf",
                                        width = "95%")),
                  fluidRow( align = "center",
                            column(12, actionButton("submit2",
                                                    label = "Click here to submit!",
                                                    width = '900px')))
                  ))


                    



ui <- dashboardPage(
  
  # ---------------------------- HEADER ----------------------------
  dashboardHeader(
    title = span(tagList(icon("robot")," Jarvik")),
    dropdownMenuCustom(type = 'message',
                       customSentence = customSentence1,
                       messageItem(
                         from = "bleejins@gmail.com", 
                         message = "",
                         icon = icon("envelope"),
                         href = "mailto:bleejins@gmail.com"
                       ),
                       icon = icon("comment")),
    dropdownMenuCustom(type = 'notification',
                       customSentence = customSentence2)
  ),
  
  # ---------------------------- SIDEBAR ----------------------------
  
  dashboardSidebar(
    selectInput("ChooseProd",
                label = "Learn More About",
                choices = productlist,
                ),
    sidebarMenuOutput("menu")
  ),
  
  # ---------------------------- BODY ----------------------------
  
  dashboardBody(
    useShinyjs(),
    tags$head(tags$script(HTML(jscode))),
    `data-proxy-click` = "insertBtn",
    tabItems(
      
      tabItem(tabName = "aboutproduct",
              fluidRow(
                wellPanel(
                  id = 'chat',
                  style = "bottom:70px",
                  # The division to show the inputs and outputs
                  tags$div(id = 'placeholder', style = "max-height: 800px; overflow: auto"),
                  hidden(tags$div(
                    id = "else", actionButton("elseBtn", "Show me something else", class = "btn btn-sm"),
                    actionButton("sourceBtn","Show me the source of the answer",  class="btn btn-sm"))),
                  div(
                    id = 'txt_label',
                    textInput('txt', h4("How can I help you?") , placeholder = "Enter your questions"),
                    actionButton('insertBtn', 'Insert'),
                    actionButton('removeBtn', 'Remove'),
                    actionButton('clearBtn', 'Clear')
                  ),
                  tags$br()
                ),
                offset = 9)
      ), 
      
      tabItem(tabName = "uploadnew",
              fluidRow(upload_box),
              fluidRow(upload_box2)),
      
      tabItem(tabName = "statstab",
              fluidRow(column(12,h1(strong("Statistics")),align = 'center')),
              fluidRow(valueBoxOutput("successrate", width = 5))
    )
  )
)
)



# ---------------------------- FUNCTIONS ----------------------------

server <- function(input,output,session){
  
  output$menu <- renderMenu({ 
    sidebarMenu(id = "sidebarmenu",
                menuItem(" Speak to Jarvik",
                         tabName = "aboutproduct",
                         icon = icon("comment")),
                menuItem(" Upload New File",
                         tabName = "uploadnew",
                         icon = icon("folder-open")),
                menuItem(" Statistics",
                         tabName = "statstab",
                         icon = icon("chart-simple"))
                
    )
  })
  
  
  
  
  # ---------------------------- UPLOAD FILE ----------------------------
  
  # On clicking submit, add new device into select input and 
  # upload file to backend document store
  # pop-up box to confirm success of upload
  observeEvent(input$submit, {
    productlist <<- c(productlist, str_split(input$device_in_file, ',')[[1]])
    updateSelectInput(session,"ChooseProd",choices= productlist, selected = input$ChooseProd)
    # read in pdf file input, and send post request
    pdf_file <- upload_file(input$file1$datapath)
    args <- list(file = pdf_file, device = input$device_in_file)
    x <- POST(upload_endpoint, body = args)
    # check status code and handle error
    if (x$status_code == 200) {
      print("yes")
      shinyalert(title = "You have successfully uploaded your file!", type = "success")
    }
    else {
    # render pop-up for failure
    # file is encrypted, please contact support
      shinyalert(title = 'Your file is encrypted. Please contact support', type = "fail")
    }
  })
  
  observeEvent(input$submit2, {
    pdf_file <- upload_file(input$file2$datapath)
    args <- list(file = pdf_file, device = input$device_in_file)
    x <- POST(upload_endpoint, body = args)
    # check status code and handle error
    if (x$status_code == 200) {
      print("yes")
      shinyalert(title = "You have successfully uploaded your file!", type = "success")
    }
    else {
      # render pop-up for failure
      # file is encrypted, please contact support
      shinyalert(title = 'Your file is encrypted. Please contact support', type = "fail")
    }
  })
  
  # ---------------------------- STATS ----------------------------
  
  # based on the current selected product, query the stats and display it
  output$successrate <- renderValueBox ({
    valueBox(
      fluidRow(column(12,h1(strong(
        paste0('Success Rate of ', input$ChooseProd)),style = "font-size:30px"),align = 'center')),
      fluidRow(column(12,h1(strong(
        paste0(chatbot(toJSON(content(GET("http://flask:5000/prediction",
                                          query = list(question = "What is the success rate of the procedure?",
                                                       device = input$ChooseProd)))),find = 1)$answer[[1]])), 
        style = "font-size: 80px"),align = 'center')),
      icon = icon('thumbs-up'),
      color = "green"
    )
  })
  

  # ---------------------------- JARVIK CHATBOT ----------------------------
  # Global variables in Jarvik chatbot
  inserted <- c() # ensure insertUI and removeUI work properly
  device <- c() # store the chosen device information
  ques <- c() # store the questions information
  btn <- c() # record each action
  source <- c() # record the source information
  file <- c() # save the returned json file of our model so that 'else' and 'source' will not send query to back-end
  found <- 1 # record what answer to show (the X-highest score)
  just_cleared <- T # record whether the window is just cleared or users haven't ask questions for the device
  
  # show the selected product name based on what you selected in the dropdown list
  # if you just cleared the window, you have to select the product in the dropdown list before you enter questions
  observeEvent(input$ChooseProd,{
    choice <- input$ChooseProd
    device <<- c(input$ChooseProd)
    id <- paste0('txt', choice)
    if (device!="") {
    insertUI(
      selector = '#placeholder',
      ui = tags$div(
        tags$b(renderText({paste("Jarvik: ",choice)})),
        tags$p(renderText({paste("Jarvik: ", "Great! What is your question?")})),
        id=id
      )
    )
      
    }
    just_cleared <<- T
    inserted <<- c(id, inserted)
  })
  
  # insert your question and display the question and answer in the window (also show 'elseBtn' and 'sourceBtn')
  # if you did not enter any question, it will give a default sentence (not show 'elseBtn' and 'sourceBtn')
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
          ques <<- c(text, ques)
          output <- build_chatbot(device, c(text), find=1)
          answer <- str_to_sentence(output[[1]]$answer)
          source <<- output[[1]]$source
          file <<- output$data
          tags$p(renderText({paste("Jarvik:[", device[length(device)], "]", answer)}))
        }else{
          ques <<- c("-1", ques)
          tags$p(renderText({paste("Jarvik: ", "I am not sure I understand you fully")}))
        },
        id = id
      )
    )
    just_cleared <<- F
    if(text!=""){
      show("else")
    }else{hide("else")}
    
    updateTextInput(session, "txt",  value= "")
    inserted <<- c(id, inserted)
  })
  
  # show the next possible answer of the same question
  # if there is no other available answers, it will give a default answer and hide this button
  observeEvent(input$elseBtn,{
    btn <<- btn + 1
    id <- paste0('txt', btn)
    found <<- found+1
    output <- chatbot(file, find=found)
    answer <- str_to_sentence(output$answer)
    source <<- output$source 
    insertUI(
      selector = '#placeholder',
      ui = tags$div(
        tags$b(paste('You: ','Show me something else about "', ques[1], '"')),
        if (answer != -1){tags$p(renderText({paste("Jarvik:[", device[length(device)], "]", answer)}))}
        else {tags$div(tags$p(renderText({paste("Jarvik:[", device[length(device)], "]", 
                                                "Sorry, I cannot come up with other answers.")})),
                       tags$p(renderText({paste("Jarvik:[", device[length(device)], "]", 
                                                "Please ask a different question!")})) 
        )},
        id = id
      )
    )
    if (answer == -1){
      found <<- 1
      hide("else")
    }
    ques <<- c(ques[1], ques)
    inserted <<- c(id, inserted)
  })
  
  # show the device, the name of the document and the page where the answer is found
  observeEvent(input$sourceBtn,{
    btn <<- btn + 1
    id <- paste0('txt', btn)
    insertUI(
      selector = '#placeholder',
      ui = tags$div(
        tags$p(renderText({paste('Jarvik: The device is "', source[[1]], '"')})),
        tags$p(renderText({paste('Jarvik: The source of the document is "', source[[2]],'"')})),
        tags$p(renderText({paste('Jarvik: You can find the information on page "', source[[3]],'"')})),
        id = id
      )
    )
    ques <<- c(ques[1], ques)
    inserted <<- c(id, inserted)
  })
  
  # remove deletes the last conversation
  # doesn't work if you have not asked a question or if you cleared conversation
  observeEvent(input$removeBtn, {
  if(input$ChooseProd != '' && !just_cleared){
        removeUI(
      selector = paste0('#', inserted[1]),
    )
    hide("else")
    inserted <<- inserted[-1]
    ques <<- ques[-1]
    if(length(ques) ==0) {
      just_cleared <<- T
      }
    }
  })
  
  # clears the entire chat history and empties the select input, 
  # need to select a product before u can ask questions again
  observeEvent(input$clearBtn, {
    if (input$ChooseProd != '') {
    removeUI(
      selector = paste0('#', inserted),
      multiple = T
    )
    hide("else")
    inserted <<- c()
    device <<- c()
    ques <<- c()
    id <- paste0('txt')
    insertUI(
      selector = '#placeholder',
      ui = tags$div(
        tags$b(renderText({paste("Jarvik: Please select a device!")})),
        tags$br(),
        id=id
      )
    )
    just_cleared <<- T
    updateSelectizeInput(session,"ChooseProd",choices= productlist, selected = "")
  }
  })
  
}

# ---------------------------- RUN APP ----------------------------

shinyApp(ui, server)

