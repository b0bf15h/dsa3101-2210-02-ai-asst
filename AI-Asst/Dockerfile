# base image to build from
FROM rocker/r-base:latest
# install development tools necessary for R and shiny
RUN apt-get update && apt-get install -y --no-install-recommends \
    sudo \
    libcurl4-gnutls-dev \
    libcairo2-dev \
    libxt-dev \
    libssl-dev \
    libssh2-1-dev \
    && rm -rf /var/lib/apt/lists/*
# install R packages used in our app
RUN install2.r shiny purrr stringr httr jsonlite bslib shinyjs DT shinydashboard shinyBS dplyr
RUN install2.r shinyalert
# set the port and host during runtime
RUN echo "local(options(shiny.port = 3838, shiny.host = '0.0.0.0'))" > /usr/lib/R/etc/Rprofile.site
# add user and group app, so we do not run container as root user (security)
RUN addgroup --system app \
    && adduser --system --ingroup app app
# set working directory
WORKDIR /home/app
# copy files into container
COPY app.R .
COPY chatbot.R .
# specify default user as app when running container, give permission to run
RUN chown app:app -R /home/app
USER app
# same port as specified above
EXPOSE 3838
# run the application when container starts
CMD ["R", "-e", "shiny::runApp('/home/app')"]
