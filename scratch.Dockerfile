# docker build --no-cache --progress=plain -t local/example:scratch -f scratch.Dockerfile .

# hadolint ignore=DL3006,DL3007
FROM golang:latest AS builder

ENV CGO_ENABLED=0

WORKDIR /go/app/

COPY <<EOF main.go
package main

import (
    "flag"
    "fmt"
    "log"
    "net/http"
    "os"
)

func handler(text string) http.HandlerFunc {
    return func(w http.ResponseWriter, r *http.Request) {
        fmt.Fprintln(w, text)
    }
}

func main() {
    port := os.Getenv("PORT")
    if port == "" {
        port = "8080"
    }

    text := flag.String("text", "Hello :-)", "set Text for Webpage")
    flag.Parse()

    http.HandleFunc("/", handler(*text))

    log.Printf("Server is running: http://0.0.0.0:%s", port)
    if err := http.ListenAndServe(":"+port, nil); err != nil {
        log.Printf("Error: %v", err)
    }
}
EOF

RUN \
    set -eux ; \
    go mod init webserver ; \
    go mod tidy ; \
    go build -o webserver . ; \
    echo "Build done !"



# hadolint ignore=DL3006
FROM scratch AS production

ARG VCS_REF
ARG BUILD_DATE
ARG VERSION

LABEL org.opencontainers.image.title="" \
      org.opencontainers.image.authors="" \
      org.opencontainers.image.vendor="" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.description="" \
      org.opencontainers.image.documentation="" \
      org.opencontainers.image.base.name="scratch" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.url="" \
      org.opencontainers.image.source="https://github.com/Tob1as/docker-build-example"

ENV PORT=8080
#ENV HEALTHCHECK_PORT=8080

# Copy static curl
COPY --from=docker.io/tobi312/tools:static-curl --chown=1000:100 /usr/bin/curl /usr/bin/curl

# Copy files from your build
COPY --from=builder --chown=1000:100 /go/app/webserver /app/webserver

# Copy HEALTHCHECK <https://github.com/Tob1as/docker-healthcheck>
#COPY --from=docker.io/tobi312/tools:healthcheck --chown=1000:100 /usr/local/bin/healthcheck /usr/local/bin/healthcheck

USER 1000

EXPOSE 8080/tcp
ENTRYPOINT ["/app/webserver"]
CMD ["--text=Nothing to see here!"]

# healthcheck without shell: https://stackoverflow.com/a/77075724  (check with: docker inspect --format='{{json .State.Health}}' <container-id>)
HEALTHCHECK --interval=10s --timeout=3s --retries=3 CMD ["/usr/bin/curl", "-f", "http://localhost:8080"]
#HEALTHCHECK --interval=10s --timeout=3s --retries=3 CMD ["/usr/local/bin/healthcheck"]