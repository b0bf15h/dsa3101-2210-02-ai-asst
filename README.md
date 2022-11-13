# dsa3101-2210-02-ai-asst

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