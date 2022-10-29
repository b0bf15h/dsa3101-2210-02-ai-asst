# syntax=docker/dockerfile:1

FROM python:3.8-slim-buster

WORKDIR /app

COPY app.py app.py
COPY document_store_setup.py document_store_setup.py
COPY Datasets Datasets

RUN pip3 install --upgrade pip
RUN pip3 install flask
RUN pip3 install farm-haystack
RUN pip3 install farm-haystack[ocr]

RUN apt-get -y update
RUN apt-get -y install build-essential libpoppler-cpp-dev pkg-config python-dev
RUN pip3 install pdftotext
RUN apt-get install -y wget
RUN apt-get install -y sudo
RUN wget --no-check-certificate https://dl.xpdfreader.com/xpdf-tools-linux-4.04.tar.gz && tar -xvf xpdf-tools-linux-4.04.tar.gz && sudo cp xpdf-tools-linux-4.04/bin64/pdftotext /usr/local/bin

ENV FLASK_APP app

ENTRYPOINT [ "python", "-u", "-m", "flask", "run", "--host=0.0.0.0"]
