# ビルドステージ
FROM debian:latest AS build-env

# API_TOKEN を引数として受け取る
ARG API_TOKEN

# 必要なツールのインストール
RUN apt-get update && apt-get install -y curl git unzip

# Flutterのインストール
RUN git clone https://github.com/flutter/flutter.git /flutter
ENV PATH="/flutter/bin:${PATH}"
RUN flutter doctor

# アプリケーションのビルド
WORKDIR /app
COPY . .
RUN flutter clean
RUN flutter pub get
# dart-defineでAPI_TOKENを渡す
RUN flutter build web --dart-define=API_TOKEN=${API_TOKEN}

# 実行ステージ
FROM nginx:alpine
COPY --from=build-env /app/build/web /usr/share/nginx/html/
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]