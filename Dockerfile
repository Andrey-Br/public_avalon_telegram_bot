FROM dart:stable AS build
WORKDIR /app
COPY pubspec.* ./
RUN dart pub get
COPY . .
RUN dart pub get --offline
RUN dart compile exe bin/dart_telegram_avalon.dart -o bin/dart_telegram_avalon
FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/bin/dart_telegram_avalon /app/bin/
EXPOSE 8080
CMD ["/app/bin/dart_telegram_avalon"]