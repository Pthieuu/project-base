FROM ghcr.io/cirruslabs/flutter:stable AS flutter-build

WORKDIR /src

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY lib ./lib
COPY web ./web
COPY analysis_options.yaml ./

RUN flutter build web --release --dart-define=API_BASE_URL=/api/

FROM php:8.3-cli

RUN apt-get update \
    && apt-get install -y --no-install-recommends libcurl4-openssl-dev \
    && docker-php-ext-install curl mysqli \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=flutter-build /src/build/web ./build/web
COPY expense_api ./expense_api
COPY tool ./tool

EXPOSE 8080

CMD ["php", "-S", "0.0.0.0:8080", "-t", "/app/build/web", "/app/tool/pwa_router.php"]
