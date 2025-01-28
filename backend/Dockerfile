FROM python:3.12.3-slim-bookworm
RUN apt-get -y update && apt-get -y upgrade

WORKDIR /root/app

RUN mkdir app
COPY app/main.py ./
COPY requirements.txt requirements.txt
COPY vertex-ai-service-account.json /root/vertex-ai-service-account.json

ENV GOOGLE_APPLICATION_CREDENTIALS=/root/vertex-ai-service-account.json

RUN pip install -r requirements.txt

ENTRYPOINT ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]