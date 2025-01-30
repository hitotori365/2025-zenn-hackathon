#!/bin/bash
# deploy.sh

# 環境変数の設定
PROJECT_ID="zenn-hacathon"
REGION="asia-northeast1"
REPO_NAME="my-app-repo"

# Artifact Registryの認証
gcloud auth configure-docker ${REGION}-docker.pkg.dev

# Dockerイメージのビルド
docker build -t ${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/app:latest .

# イメージのプッシュ
docker push ${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/app:latest