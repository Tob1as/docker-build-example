# docker build --no-cache --progress=plain -t local/example:debian -f debian.Dockerfile .

# hadolint ignore=DL3007
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



# hadolint ignore=DL3007
FROM debian:latest AS production

ARG VCS_REF
ARG BUILD_DATE
ARG VERSION

ENV DEBIAN_FRONTEND=noninteractive

LABEL org.opencontainers.image.title="" \
      org.opencontainers.image.authors="" \
      org.opencontainers.image.vendor="" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.description="" \
      org.opencontainers.image.documentation="" \
      org.opencontainers.image.base.name="docker.io/library/debian:latest" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.url="" \
      org.opencontainers.image.source="https://github.com/Tob1as/docker-build-example"

ENV PORT=8080
#ENV HEALTHCHECK_PORT=8080

# hadolint ignore=DL3008
RUN set -eux ; \
    apt-get update ; \
    apt-get install -y --no-install-recommends \
        curl \
        netcat-openbsd \
    ; \
    rm -rf /var/lib/apt/lists/* ; \
    echo "Install packages done!"

# Copy files from your build
COPY --from=builder --chown=nobody:nogroup /go/app/webserver /app/webserver

# Copy HEALTHCHECK <https://github.com/Tob1as/docker-healthcheck>
# hadolint ignore=DL3022
#COPY --from=docker.io/tobi312/tools:healthcheck --chown=nobody:nogroup /usr/local/bin/healthcheck /usr/local/bin/healthcheck

USER nobody

EXPOSE 8080/tcp
ENTRYPOINT ["/app/webserver"]
CMD ["--text=Nothing to see here!"]

# healthcheck (check with: docker inspect --format='{{json .State.Health}}' <container-id>)
HEALTHCHECK --interval=10s --timeout=3s --retries=3 CMD /usr/bin/curl -f http://localhost:8080 || exit 1
#HEALTHCHECK --interval=10s --timeout=3s --retries=3 CMD /usr/bin/nc -z -w1 localhost 8080 || exit 1
#HEALTHCHECK --interval=10s --timeout=3s --retries=3 CMD ["/usr/local/bin/healthcheck"]