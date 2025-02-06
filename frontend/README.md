# simple_speech_to_text
speech-to-textを使用したアプリ

```
# 環境変数の設定
export PROJECT_ID="your-project"
export REGION="your-region"
export REPO_NAME="your-repo"
export API_TOKEN="your-actual-token"

# Terraformでインフラを作成（Artifact Registryのみ）
terraform init
terraform apply -target=google_artifact_registry_repository.frontend_repo

# Dockerイメージのビルドとプッシュ
docker build --no-cache --platform linux/amd64 \
  --build-arg API_TOKEN=${API_TOKEN} \
  -t frontend .

docker tag frontend ${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/frontend:latest
docker push ${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/frontend:latest

# 残りのインフラをデプロイ
terraform apply
```