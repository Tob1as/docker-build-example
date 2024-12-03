# docker build --no-cache --progress=plain -t local/example:distroless -f distroless.debian.Dockerfile .

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



# Simple example of how to properly extract packages for reuse in distroless
# Taken from: https://github.com/GoogleContainerTools/distroless/issues/863#issuecomment-986062361
# and: https://github.com/fluent/fluent-bit/blob/master/dockerfiles/Dockerfile#L100-L159
FROM debian:bookworm-slim AS deb-extractor

# We download all debs locally then extract them into a directory we can use as the root for distroless.
# We also include some extra handling for the status files that some tooling uses for scanning, etc.
WORKDIR /tmp
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# List of packages for download separated by spaces.
ENV PACKAGE_LIST="curl netcat-openbsd"

RUN \
    #echo "deb http://deb.debian.org/debian bookworm-backports main" >> /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y apt-rdepends tree && \
    # Search subpackages for package (apt-rdepends PACKAGE | grep -v "^ " | sort -u | tr '\n' ' ')
    packages=$(for package in $PACKAGE_LIST; do \
        apt-rdepends $package 2>/dev/null | \
        grep -v "^ " | \
        grep -v "^PreDepends:" | \
        sort -u; \
    done | sort -u) && \
    #packages=$PACKAGE_LIST ; \
    # Download packages
    echo ">> Packages to Download: $(echo $packages | tr '\n' ' ')" && \
    apt-get download \
        $packages \
    && \
    mkdir -p /dpkg/var/lib/dpkg/status.d/ && \
    for deb in *.deb; do \
        package_name=$(dpkg-deb -I "${deb}" | awk '/^ Package: .*$/ {print $2}'); \
        echo "Processing: ${package_name}"; \
        dpkg --ctrl-tarfile "$deb" | tar -Oxf - ./control > "/dpkg/var/lib/dpkg/status.d/${package_name}"; \
        dpkg --extract "$deb" /dpkg || exit 10; \
    done \
    && \
    echo "Packages have been processed !"

# Remove unnecessary files extracted from deb packages like man pages and docs etc.
RUN find /dpkg/ -type d -empty -delete && \
    rm -r /dpkg/usr/share/doc/

# List directory and file structure
RUN tree /dpkg



# We want latest at time of build
# hadolint ignore=DL3006,DL3007
FROM gcr.io/distroless/static-debian12:latest AS production

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
      org.opencontainers.image.documentation="https://github.com/GoogleContainerTools/distroless" \
      org.opencontainers.image.base.name="gcr.io/distroless/static-debian12" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.url="" \
      org.opencontainers.image.source="https://github.com/Tob1as/docker-build-example"

ENV PORT=8080
#ENV HEALTHCHECK_PORT=8080

# Copy the libraries from the extractor stage into root
COPY --from=deb-extractor /dpkg /

# Copy files from your build
COPY --from=builder --chown=nobody:nogroup /go/app/webserver /app/webserver

# Copy HEALTHCHECK <https://github.com/Tob1as/docker-healthcheck>
#COPY --from=docker.io/tobi312/tools:healthcheck --chown=nobody:nogroup /usr/local/bin/healthcheck /usr/local/bin/healthcheck

USER nobody

EXPOSE 8080/tcp
ENTRYPOINT ["/app/webserver"]
CMD ["--text=Nothing to see here!"]

# healthcheck without shell: https://stackoverflow.com/a/77075724  (check with: docker inspect --format='{{json .State.Health}}' <container-id>)
HEALTHCHECK --interval=10s --timeout=3s --retries=3 CMD ["/usr/bin/curl", "-f", "http://localhost:8080"]
#HEALTHCHECK --interval=10s --timeout=3s --retries=3 CMD ["/bin/nc.openbsd", "-z", "-w1", "localhost", "8080"]
#HEALTHCHECK --interval=10s --timeout=3s --retries=3 CMD ["/usr/local/bin/healthcheck"]