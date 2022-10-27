# syntax=docker/dockerfile:1

FROM python:3.10.6-slim-buster

WORKDIR /app

COPY 
ADD templates templates

RUN pip3 install --upgrade pip
RUN pip3 install -r requirements.txt
RUN python train_model.py

ENV FLASK_APP lm1

ENTRYPOINT [ "python", "-u", "-m", "flask", "run", "--host=0.0.0.0"]
