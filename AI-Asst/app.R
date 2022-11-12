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

source("chatbot.R",local=T)
productlist <- c('Watchman', 'Atriclip', 'Lariat')
upload_endpoint <- "http://flask:5000/upload"
options(shiny.maxRequestSize=40*1024^2) 

# ---------------------------- HELPER FUNCTIONS (temp) ----------------------------

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

customSentence <- function(numItems,type) {
  paste("Feedback & Suggestions")
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


#TEST BOX FUNCTION

upload_box <- box(title = "Upload Data",
                  status = "info", solidHeader = TRUE, width = 12,
                  
                  fluidRow(
                    column(10, h4(icon("upload"),"Upload a PDF file containing information about your medical device"))),
                  fluidRow(
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



ui <- dashboardPage(
  
  # ---------------------------- HEADER ----------------------------
  dashboardHeader(
    titleWidth = 550,
    title = "AI Assistant for Medical Sales Representative",
    dropdownMenuCustom(type = 'message',
                       customSentence = customSentence,
                       messageItem(
                         from = "bleejins@gmail.com", 
                         message = "",
                         icon = icon("envelope"),
                         href = "mailto:bleejins@gmail.com"
                       ),
                       icon = icon("comment"))
  ),
  
  # ---------------------------- SIDEBAR ----------------------------
  
  dashboardSidebar(
    selectInput("ChooseProd",
                label = "Learn More About",
                choices = productlist),
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
              fluidRow(upload_box)
      )
    )
  )
)


# ---------------------------- FUNCTIONS ----------------------------

server <- function(input,output,session){
  
  output$menu <- renderMenu({ 
    sidebarMenu(id = "sidebarmenu",
                menuItem("Speak to Jarvik",
                         tabName = "aboutproduct",
                         icon = icon("comment")),
                menuItem("Upload New File",
                         tabName = "uploadnew",
                         icon = icon("folder"))
                
    )
  })
  
  
  
  
  # ---------------------------- UPLOAD FILE ----------------------------
  
  observeEvent(input$submit, {
    productlist <<- c(productlist, str_split(input$device_in_file, ',')[[1]])
    updateSelectInput(session,"ChooseProd",choices= productlist)
    # read in pdf file input, and send post request
    pdf_file <- upload_file(input$file1$datapath)
    args <- list(file = pdf_file, device = input$device_in_file)
    x <- POST(upload_endpoint, body = args)
    # check status code and handle error
    if (x$status_code == 200) {
      print("yes")
      shinyalert(title = "You have successfully uploaded your file!", type = 'success')
    }
    else {
    # render pop-up for failure
    # file is encrypted, please contact support 
      shinyalert(title = "Your file is encrypted, please contact support", type = 'error')
    }
  })
  
  # ---------------------------- JARVIK CHATBOT ----------------------------
  inserted <- c()
  device <- c()
  ques <- c()
  btn <- c()
  source <- c()
  
  observeEvent(input$ChooseProd,{
    choice <- input$ChooseProd
    device <<- c(input$ChooseProd)
    id <- paste0('txt', choice)
    insertUI(
      selector = '#placeholder',
      ui = tags$div(
        tags$b(renderText({paste("Jarvik: ",choice)})),
        tags$p(renderText({paste("Jarvik: ", "Great! What is your question?")})),
        id=id
      )
    )
    inserted <<- c(id, inserted)
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
          ques <<- c(text)
          output <- build_chatbot(device, ques, find=1)
          # answer <- output$answer
          # source <<- output$source 
          # tags$p(renderText({paste("Jarvik:[", device[length(device)], "]", answer)}))
        }else{
          tags$p(renderText({paste("Jarvik: ", "I am not sure I understand you fully")}))
        },
        id = id
      )
    )
    
    if(text!=""){
      show("else")
    }else{hide("else")}
    
    updateTextInput(session, "txt",  value= "")
    inserted <<- c(id, inserted)
  })
  
  observeEvent(input$elseBtn,{
    btn <<- btn + 1
    id <- paste0('txt', btn)
    output <- build_chatbot(device, ques[1], input$elseBtn+1)
    answer <- output$answer
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
      hide("else")
      ques <<- c()
    }else{ques <<- c(ques[1], ques)}
    inserted <<- c(id, inserted)
  })
  
  observeEvent(input$sourceBtn,{
    btn <<- btn + 1
    id <- paste0('txt', btn)
    insertUI(
      selector = '#placeholder',
      ui = tags$div(
        tags$p(renderText({paste("Jarvik: ", source)})),
        id = id
      )
    )
    inserted <<- c(id, inserted)
  })
  
  observeEvent(input$removeBtn, {
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
          tags$b(renderText({paste("Jarvik: ","Please enter the device you want to search for")}))
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

# ---------------------------- RUN APP ----------------------------

shinyApp(ui, server)

