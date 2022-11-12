library(jsonlite)
library(httr)
library(dplyr)

######## answer1 #########
chatbot <- function(file="output.json", find=1) {
  docs <- jsonlite::fromJSON(file)
  find <- as.numeric(find)
  
  output <- docs['answers'][[1]]
  filter_answer <- output %>% as_tibble() %>% select("answer")
  filter_answer <- Filter(function(x) {x!=""}, filter_answer[[1]])
  filter_source <- output %>% as_tibble() %>% select("meta")
  filter_device <- Filter(function(x) {typeof(x)!="NULL"}, filter_source[[1]][[2]])
  filter_name <- Filter(function(x) {typeof(x)!="NULL"}, filter_source[[1]][[3]])
  filter_page <- Filter(function(x) {typeof(x)!="NULL"}, filter_source[[1]][[4]])
  if (length(filter_answer) < find){
    answer <- "-1" #"No more information available"
    source <- "-1"
  }else{
    answer <- filter_answer[[find]]
    source <- list(device = filter_device[[find]], docs_name = filter_name[[find]], docs_page = filter_page[[find]])
  }
  return (list(answer = answer,source = source))
}


build_chatbot <- function(devices, ques, find=1){
  # connect to model file and generate json object
  url <-  "http://flask:5000/prediction"
  body <- list(question = ques[[length(ques)]], device = devices[[length(devices)]])
  # print question and devices
  print(ques)
  print(devices)
  resp <- GET(url, query = body)
  # print structure of response
  # file = http_type(resp)
  file <- content(resp, type="application/json")
  print(str(file))
  print("----------------------")
  print(class(file))
  data <- toJSON(file)
  write(data, "output.json")
<<<<<<< HEAD
  return(chatbot(data, find))
=======
  # data="output.json"
  return(list(chatbot(data, find),data = data))
>>>>>>> a31d880d59831bb278214e2c1cbc67ae8fff4e45
}

