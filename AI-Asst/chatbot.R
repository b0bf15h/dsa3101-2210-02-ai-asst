library(jsonlite)
library(httr)


######## answer1 #########
chatbot <- function(file="outputs.json", find=1) {
  docs <- jsonlite::fromJSON(file)
  find <- as.numeric(find)
  answers <- docs['answers'][[1]]
  if (length(answers) < find){
    output <- "-1" #"Sorry, no more information available.  Please search for another device!"
  }else{
    output <- answers %>% as_tibble() %>% 
      arrange(desc(score)) %>% slice(find) %>% 
      select("answer") %>% as.character()
  }
  return (output)
}

build_chatbot <- function(device, ques, find=1){
  # connect to model file and generate json object
  url = "http://flask:5000/"
  body = list(question = ques, device = device)
  resp<-GET(url, path = "prediction", params = body)
  # t1<-content(resp, type="application/json")
  # file = "outputs.json"
  file = http_type(resp)
  output <- chatbot(file, find)
  return (output)
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

