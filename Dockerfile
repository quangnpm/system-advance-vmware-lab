FROM alpine:3.24 AS content
WORKDIR /src
COPY app/ ./
RUN test -s index.html

FROM nginx:stable-alpine3.24 AS runtime
COPY --from=content /src/ /usr/share/nginx/html/
EXPOSE 80
HEALTHCHECK --interval=15s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -q -O /dev/null http://127.0.0.1/ || exit 1
