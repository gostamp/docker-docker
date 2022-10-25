# syntax=docker/dockerfile:1.4
FROM golang:1.19.2-alpine3.16 AS dive

RUN mkdir -p /go/src/github.com/wagoodman/dive
WORKDIR /go/src/github.com/wagoodman/dive

SHELL ["/bin/sh", "-o", "errexit", "-c"]
RUN <<EOF
    apk update
    apk add --no-cache \
        "git~=2.36.3" \
        "gcc~=11.2.1" \
        "musl-dev~=1.2.3"

    git clone --depth 1 https://github.com/jauderho/dive.git /go/src/github.com/wagoodman/dive

    export CGO_ENABLED=0
    go get -u all
    go build -v \
        -o /usr/local/bin/dive \
        -trimpath \
        -buildmode=pie \
        -ldflags="-s -w -X main.version=$(git rev-parse HEAD)"
EOF

FROM aquasec/trivy:0.32.1 AS trivy

FROM goodwithtech/dockle:v0.4.9 AS dockle

FROM alpine:3.16 AS final

COPY --from=dive /usr/local/bin/dive /usr/local/bin/dive
COPY --from=dockle /usr/bin/dockle /usr/local/bin/dockle
COPY --from=trivy /usr/local/bin/trivy /usr/local/bin/trivy

RUN apk add --no-cache \
    "bash~=5.1.16"

ARG APP_GID
ARG APP_UID
# See: https://docs.docker.com/engine/reference/builder/#automatic-platform-args-in-the-global-scope
ARG TARGETARCH

ENV APP_GID="${APP_GID:-10001}" \
    APP_UID="${APP_UID:-10001}" \
    APP_HOME="/home/app" \
    APP_DIR="/app" \
    APP_USER="app"

SHELL ["/bin/bash", "-o", "pipefail", "-o", "errexit", "-c"]
RUN <<EOF
    mkdir -p "${APP_DIR}" "${APP_HOME}"
    chown -R "${APP_UID}:${APP_GID}" \
        "${APP_DIR}" \
        "${APP_HOME}"

    addgroup --gid "${APP_GID}" "${APP_USER}"
    adduser --uid "${APP_UID}" --ingroup "${APP_USER}" \
        --shell /bin/bash --home "${APP_HOME}" --disabled-password "${APP_USER}"

    arch="${TARGETARCH}"
    version="v1.11.0"
    bin_url="https://storage.googleapis.com/container-structure-test/${version}/container-structure-test-linux-${arch}"
    wget --no-verbose --output-document=/usr/local/bin/container-structure-test "${bin_url}"
    chown root:root /usr/local/bin/container-structure-test
    chmod 0755 /usr/local/bin/container-structure-test
EOF

COPY --chown="${APP_UID}:${APP_GID}" ./etc/bashrc.sh "${APP_HOME}/.bashrc"
COPY --chown="${APP_UID}:${APP_GID}" ./bin/* "${APP_DIR}/bin/"

HEALTHCHECK NONE

WORKDIR "${APP_DIR}"
USER "${APP_USER}"
ENTRYPOINT ["/app/bin/entrypoint.sh"]
CMD ["/app/bin/command.sh"]
