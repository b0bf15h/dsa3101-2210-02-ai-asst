library(jsonlite)
library(httr)
library(dplyr)

######## answer1 #########
chatbot <- function(file="output.json", find=1) {
  docs <- jsonlite::fromJSON(file)
  find <- as.numeric(find)
  
  output <- docs['answers'][[1]]
  # filter the answer and source (device,name,page)
  # if there is any NULL answer returned, we will discard that
  filter_answer <- output %>% as_tibble() %>% select("answer")
  filter_answer <- Filter(function(x) {x!=""}, filter_answer[[1]])
  filter_source <- output %>% as_tibble() %>% select("meta")
  filter_device <- Filter(function(x) {typeof(x)!="NULL"}, filter_source[[1]][[2]])
  filter_name <- Filter(function(x) {typeof(x)!="NULL"}, filter_source[[1]][[3]])
  filter_page <- Filter(function(x) {typeof(x)!="NULL"}, filter_source[[1]][[4]])
  
  if (length(filter_answer) < find){
    answer <- "-1" # no more answers available (cannot find the X-highest score answer)
    source <- "-1"
  }else{ # find and return the available answer
    answer <- filter_answer[[find]]
    source <- list(device = filter_device[[find]], docs_name = filter_name[[find]], docs_page = filter_page[[find]])
  }
  return (list(answer = answer,source = source))
}


build_chatbot <- function(devices, ques, find=1){
  # connect to prediction endpoint from app.py
  # rerieve JSON object to be processed in chatbot()
  url <-  "http://flask:5000/prediction"
  body <- list(question = ques[[length(ques)]], device = devices[[length(devices)]])
  resp <- GET(url, query = body)
  file <- content(resp, type="application/json")
  data <- toJSON(file)
  return(list(chatbot(data, find),data = data))

}

