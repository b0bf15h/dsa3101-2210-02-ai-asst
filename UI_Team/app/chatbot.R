library(jsonlite)


######## answer1 #########
chatbot <- function(file="answers1.js", find=1) {
  docs <- jsonlite::fromJSON(file)
  find <- as.numeric(find)
  
  answers <- docs['answers'][[1]]
  if (length(answers) < find){
    output <- "Sorry, no more infomation available.  Please search for another device!"
  }else{
    output <- answers %>% as_tibble() %>% 
      arrange(desc(score)) %>% slice(find) %>% 
      select("answer") %>% as.character()
  }
  output
}

build_chatbot <- function(device, ques, find=1){
  # connect to model file and generate json object
  file = "answers1.js"
  output <- chatbot(file, find)
}

check_device <- function(device, productlist){
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

