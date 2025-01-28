FROM python:3.12.3-slim-bookworm

RUN apt-get -y update && apt-get -y upgrade

WORKDIR /workspace

# 開発用の追加パッケージをインストール
RUN apt-get install -y git curl

# Google Cloud SDK のインストール
RUN curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-454.0.0-linux-x86_64.tar.gz && \
    tar -xf google-cloud-cli-454.0.0-linux-x86_64.tar.gz && \
    ./google-cloud-sdk/install.sh --quiet && \
    rm google-cloud-cli-454.0.0-linux-x86_64.tar.gz

ENV PATH $PATH:/workspace/google-cloud-sdk/bin