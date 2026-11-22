FROM dart:3.13.7@sha256:854f3c50b1cbd4a5a54c9fa67d4f5b6702ac49b4a26d21a80e7712a72528b215 AS build

# Resolve app dependencies.
WORKDIR /app
COPY pubspec.* ./
RUN dart pub get --enforce-lockfile

# Copy app source code (except anything in .dockerignore) and AOT compile app.
COPY . .
RUN dart compile exe bin/server.dart -o bin/server

# Build minimal serving image from AOT-compiled `/server`
# and the pre-built AOT-runtime in the `/runtime/` directory of the base image.
FROM alpine:3.24.4@sha256:f59abe656b692d901e184be3445e084786602108599d2a51d229c0f5a48c71bf
RUN apk add --no-cache curl
COPY --from=build /runtime/ /
COPY --from=build /app/bin/server /app/bin/
COPY log-filter.sh /app/bin/
ENV TINI_KILL_PROCESS_GROUP=1
ENTRYPOINT ["/bin/sh", "/app/bin/log-filter.sh"]

# Start server.
EXPOSE 8000
CMD ["/app/bin/server"]
