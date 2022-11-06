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

source("chatbot.R",local=T)
productlist <- c('Watchman', 'Atriclip', 'Lariat')

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
  paste("Feedback & suggestions")
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
    icon <- switch(type, messages = shiny::icon("envelope"), 
                   notifications = shiny::icon("warning"), tasks = shiny::icon("tasks"))
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
    tags$head(tags$script(HTML(jscode))),
    `data-proxy-click` = "insertBtn",
    tabItems(
    
    tabItem(tabName = "aboutproduct",
            fluidRow(
              hidden(wellPanel(
                id = 'chat',
                style = "bottom:70px",
                tags$div(id = 'placeholder', style = "max-height: 800px; overflow: auto"),
                hidden(tags$div(
                  id = "else",
                  hidden(
                    actionButton("elseBtn", "Show me something else", class = "btn btn-sm")
                  ),
                  actionButton("switchBtn", "Search for another device",  class =
                                 "btn btn-sm")
                )),
                div(
                  id = 'txt_label',
                  textInput('txt', h4("How can I help you?") , placeholder = "Enter your questions"),
                  actionButton('insertBtn', 'Insert'),
                  actionButton('removeBtn', 'Remove'),
                  actionButton('clearBtn', 'Clear')
                ),
                tags$br()
              )),
              offset = 9)
    ), 
    
    tabItem(tabName = "uploadnew",
            fluidRow(
              column(10, tags$h1(strong("Upload a PDF file containing information about your medical device"),style = "font-size:20px"),
                     fluidRow(
                       column(10, textInput("device_in_file",
                                           "Please input the name of your product",
                                           placeholder = "Name of your product")),
                       column(10, fileInput("file1",
                                           label="Select a file", 
                                           accept=".pdf")),
                       column(10,actionButton("submit",
                                              label = "Submit")))),
            )
    )
  ),

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
                         icon = icon("upload"))

                )
  })

  
  
  
# ---------------------------- UPLOAD FILE ----------------------------
  
  observeEvent(input$submit, {
    productlist <<- c(productlist, str_split(input$device_in_file, ',')[[1]])
    updateSelectInput(session,"ChooseProd",choices= productlist)
  })
  
  
# ---------------------------- JARVIK CHATBOT ----------------------------
  inserted <- c()
  device <- c()
  ques <- c()
  btn <- c()
  
  
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
          else {found <- -1} # Have previous device
          
          if(found==0){
            # Not valid device
            tags$div(tags$p(renderText({paste("Jarvik: ", "Sorry I do not have infomation for this device!")})),
                     tags$p(renderText({paste("Jarvik: Please enter another device!")})),
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
                                                "Please ask a different question!")})) 
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

