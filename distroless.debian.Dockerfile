# docker build --no-cache --progress=plain --target=production -t local/example:distroless -f distroless.debian.Dockerfile .

# ============================================================================
# Using Google Distroless as image for a simple Go Webserver (example)
# https://github.com/googlecontainertools/distroless
# ============================================================================

# ============================================================================
# Stage 1: Build the simple Go Webserver (example)
# ============================================================================

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

# ============================================================================
# Stage 2: Extract required packages for distroless
# ============================================================================

# Simple example of how to properly extract packages for reuse in distroless
# Taken from: https://github.com/GoogleContainerTools/distroless/issues/863#issuecomment-986062361
# and: https://github.com/fluent/fluent-bit/blob/master/dockerfiles/Dockerfile#L125-L183
FROM debian:trixie-slim AS deb-extractor

# We download all debs locally then extract them into a directory we can use as the root for distroless.
# We also include some extra handling for the status files that some tooling uses for scanning, etc.
WORKDIR /tmp
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# List of packages for download separated by spaces.
ENV PACKAGE_LIST="curl netcat-openbsd"

# DL3008 (pin package versions) is intentionally ignored (throwaway build stage).
# hadolint ignore=DL3008
RUN \
    apt-get update && \
    apt-get install -y --no-install-recommends apt-rdepends tree && \
    # Option 1: download only the packages listed in PACKAGE_LIST
    #packages="${PACKAGE_LIST}" && \
    # Option 2: also resolve all (recursive) dependencies via apt-rdepends.
    packages=$(echo "${PACKAGE_LIST}" | xargs apt-rdepends 2>/dev/null | grep -v "^ " | grep -v "^PreDepends:" | sort -u) && \
    # Download packages (xargs splits the list, avoids unquoted word splitting, SC2086)
    echo ">> Packages to Download: $(echo "${packages}" | tr '\n' ' ')" && \
    echo "${packages}" | xargs apt-get download \
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
RUN rm -rf /dpkg/usr/share/doc/ /dpkg/usr/share/man/ && \
    find /dpkg/ -type d -empty -delete

# List directory and file structure
RUN tree /dpkg


# ============================================================================
# Stage 3a: Debug image with distroless
# Select with: --target debug
# ============================================================================

FROM gcr.io/distroless/static-debian13:debug-nonroot AS debug

ARG VCS_REF
ARG BUILD_DATE
ARG VERSION

LABEL org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.source="https://github.com/Tob1as/docker-build-example"

ENV PORT=8080
COPY --from=deb-extractor /dpkg /
COPY --from=builder --chown=65532:65532 /go/app/webserver /app/webserver

# User nonroot
#USER 65532

EXPOSE 8080/tcp
ENTRYPOINT ["/app/webserver"]
CMD ["--text=Nothing to see here!"]

# ============================================================================
# Stage 3b: Production image with distroless
# Select with: --target production
# ============================================================================

FROM gcr.io/distroless/static-debian13:nonroot AS production

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
      org.opencontainers.image.base.name="gcr.io/distroless/static-debian13" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.url="" \
      org.opencontainers.image.source="https://github.com/Tob1as/docker-build-example"

ENV PORT=8080
#ENV HEALTHCHECK_PORT=8080

# Copy the libraries from the extractor stage into root
COPY --from=deb-extractor /dpkg /

# Copy files from your build
COPY --from=builder --chown=65532:65532 /go/app/webserver /app/webserver

# Copy HEALTHCHECK <https://github.com/Tob1as/docker-healthcheck>
#COPY --from=docker.io/tobi312/tools:healthcheck --chown=65532:65532 /usr/local/bin/healthcheck /usr/local/bin/healthcheck

# User nonroot (ID: 65532)
#USER 65532

EXPOSE 8080/tcp
ENTRYPOINT ["/app/webserver"]
CMD ["--text=Nothing to see here!"]

# healthcheck without shell: https://stackoverflow.com/a/77075724  (check with: docker inspect --format='{{json .State.Health}}' <container-id>)
HEALTHCHECK --interval=10s --timeout=3s --retries=3 CMD ["/usr/bin/curl", "-f", "http://localhost:8080"]
#HEALTHCHECK --interval=10s --timeout=3s --retries=3 CMD ["/bin/nc.openbsd", "-z", "-w1", "localhost", "8080"]
#HEALTHCHECK --interval=10s --timeout=3s --retries=3 CMD ["/usr/local/bin/healthcheck"]