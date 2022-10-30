import requests

URL = "http://localhost:5000/prediction"

question = "What is the dimension of the Watchman device"
device = "Watchman"
  
# defining a params dict for the parameters to be sent to the API
PARAMS = {'question':question, "device":device}
  
# sending get request and saving the response as response object
r = requests.get(url = URL, params = PARAMS)
  
# extracting data in json format
data = r.json()
  
  
print(data)
