library(jsonlite)
library(httr)

######## answer1 #########
chatbot <- function(file="answers1.js", find=1) {
  docs <- jsonlite::fromJSON(file)
  help(fromJSON)
  find <- as.numeric(find)
  
  answers <- docs['answers'][[1]]
  if (length(answers) < find){
    output <- "-1" #"Sorry, no more information available.  Please search for another device!"
  }else{
    output <- answers %>% as_tibble() %>% 
      arrange(desc(score)) %>% slice(find) %>% 
      select("answer") %>% as.character()
    source <- answers %>% as_tibble() %>% 
      arrange(desc(score)) %>% slice(find) %>% 
      select("meta") 
  }
  return (list(answer = output,source = source))
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
  return(chatbot(file, find))
}

check_device <- function(device, productlist){
  productlist <- unique(productlist[productlist != ""])
  pos <- which(lapply(paste0("(.*)?", productlist, "(.*)?"), grep, x = device, ignore.case = TRUE) == 1)
  if (length(pos) == 0){
    pos <- 0
  }
  pos # pos == 0 means "Not Found", any other number means "Found"
}

# input <- ""
# cat("Eliza: Hello, I am Eliza!\n")
# while (TRUE) {
#   input_num <- readline("You: ")
#   if (input_num == "quit") break
#   # num <- readline()
#   cat("Eliza:", chatbot(find=input_num))
# }

