# syntax=docker/dockerfile:1

FROM python:3.10.6-slim-buster

WORKDIR /app

COPY app.py app.py

RUN pip3 install --upgrade pip
RUN pip3 install flask
RUN pip3 install farm-haystack
RUN pip3 install farm-haystack[ocr]

ENV FLASK_APP app

ENTRYPOINT [ "python", "-u", "-m", "flask", "run", "--host=0.0.0.0"]
