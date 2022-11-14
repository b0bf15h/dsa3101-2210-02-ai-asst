# dsa3101-2210-02-ai-asst

AI Assistant Application for medical device sales reps

Final application codes are found in AI-Asst directory
Modelling_team directory contains codes/files used by modelling team for development
while UI_team directory contains codes/files used by front-end team for development

Steps to run application:
1) From the AI-Asst directory run: docker compose up (building of images may take a while)
2) To populate the database with medical documents sourced by the modelling team,
run a bash in the flask container using: docker exec -it ai-asst-flask-1 bash  
Then execute python script in bash using command: python3 document_store_setup.py
3) To access application go to localhost:3838
4) Flask app may take a while to start up, thus do wait for the flask container logs to show that the flask application is running before querying

Guide for using shiny application:
1) As stated above, do wait for the flask container to be up and running before you open up shiny via localhost:3838
2) When you first open the webpage, you land on the Speak to Jarvik tab. The default selected product is Watchman but
   you can select a different product using the prompt "Learn More About".
3) After selecting a device, Jarvik will prompt you for a question. Type it in the textbox below "How can I help you?" and press click on Insert to submit your       
   question. Alternatively, you can press "Enter" on your keyboard instead of clicking on Insert. The query process might take awhile, do not query more 
   than once as it would send a repeat query and cause slow down.
4) Once Jarvik returns the answer, you can click on Show me something else for a different answer to the same question should the initial answer be unsatisfactory.
   You can also click on Show me the source of the answer and Jarvik will reply with the device, the name of the document and the page where the answer is found.
5) Should the conversation become too long and take up too much of the screen, you can click on Remove to delete the last conversation, 
   note that clicking on remove does nothing if you have yet to submit a question. 
6) You can also click on Clear to clear the entire conversation. After clearing, the previously selected device will be cleared and you will be prompted to 
   select a device again before you can ask questions. Submitting questions without choosing a device will cause the application to hang.
7) Click on the Upload New File tab to upload your own pdf file into our document store. Input the name of your product and select a file by clicking on Browse.
   After that, click on Submit and wait for a Green Tick to appear in the pop-up box. Now, the product name can also be found in the select device dropdown.
   Do not submit encrypted files or files that are larger than 40MB, if you need to do so, please contact the admin via email in the top right corner.
8) Click on the Statistics tab and wait for the success rate of the procedure to show up. Select a different device to see the success rate for that device. 
   Note that this may not be accurate for new devices that you uploaded due to lack of information.
9) If you want to close the menu on the top left to use the app in full screen, click on the 3 horizontal bars in the top left corner. 
   Click on it again to open the menu.
10) Click on the message button in the top right corner and then click on the email address to sent your feedbacks and suggestions.
11) Click on the alert icon in the top right corner to view our disclaimer.
   
