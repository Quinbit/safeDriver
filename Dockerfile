FROM python:latest

WORKDIR /usr/bin/app

COPY requirements.txt requirements.txt

RUN pip install -r requirements.txt

COPY . .

CMD python app.py
