### build
```
docker build --platform linux/amd64 -t app .
docker tag app ${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/app:latest
docker push ${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/app:latest
```

### devcontainer内/appで実行
```
uvicorn main:app --host 0.0.0.0 --port 8080 --reload
```

### bodyの中身
```
{
    "messages": [
        {
            "role": "user",
            "content": "こんにちは"
        },
        {
            "role": "assistant",
            "content": "こんにちは！藁人形です。どのようなお手伝いができますか？"
        },
        {
            "role": "user",
            "content": "え、なんて？名前何ですか？"
        }
    ]
}
```
