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
library(shinydashboard)
library(shinyBS)

source("chatbot.R",local=T)
productlist <- c('Watchman', 'Atriclip', 'Lariat')

ui <- dashboardPage(
  
  # ---------------------------- HEADER ----------------------------
    
  dashboardHeader(
    title = "AI Assistant for Medical Sales Representative"),
  
  # ---------------------------- SIDEBAR ----------------------------
  
  dashboardSidebar(
    sidebarMenuOutput("menu")
  ),
  
  # ---------------------------- BODY ----------------------------
  
  dashboardBody(tabItems(
    
    tabItem(tabName = "aboutproduct",
            fluidRow(div(
              div(style = "display:inline-block;",
                  actionButton(inputId = "description",
                               label = "Description",
                               icon = NULL,
                               width = "300px")),
              div(style = "display:inline-block;",
                  actionButton(inputId = "why",
                               label = "Why choose me",
                               icon = NULL,
                               width = "300px")),
              div(style = "display:inline-block;",
                  actionButton(inputId = "how",
                               label = "Surgical Procedure",
                               icon = NULL,
                               width = "300px"))
            )
            )
    ),
    tabItem(tabName = "uploadnew",
            fluidRow(
              column(6, "Upload a pdf file containing information about your medical device:",
                     fluidRow(
                       column(5, fileInput("file1",
                                           label="", 
                                           accept=".pdf")))),
              column(3, 
                     textInput("device_in_file", 
                               "Find out more about other devices! If there are multiple devices, please separate by comma without spaces.", 
                               placeholder = "E.g. Device A,Device B"))
            )
    )
  ),
  textOutput("text")
  )
)
          

# ---------------------------- FUNCTIONS ----------------------------

server <- function(input,output,session){
  
  output$menu <- renderMenu({ 
    sidebarMenu(id = "sidebarmenu",
                menuItem("About Product",
                         tabName = "aboutproduct",
                         icon = NULL
                         menuSubItem("Choose Product",
                                      )),
                menuItem("Upload New File",
                         tabName = "uploadnew",
                         icon = NULL)

                )
  })
  
  observeEvent(input$sidebarmenu, {
    output$text <- renderText({
      if(input$sidebarmenu == "aboutproduct"){
        "- DESCRIPTION OF PRODUCT -"
      }else if(input$sidebarmenu == "uploadnew"){
        "- UPLOAD NEW FILE HERE -"
      }
    })
  })
  
  observeEvent(input$description,{
    output$text <- renderText("- DESCRIPTION OF PRODUCT -")
  })
  
  observeEvent(input$why,{
    output$text <- renderText("- WHY CHOOSE PRODUCT? -")
  })
  
  observeEvent(input$how,{
    output$text <- renderText("- SURGICAL PROCEDURES -")
  })
  
}

# ---------------------------- RUN APP ----------------------------

shinyApp(ui, server)

