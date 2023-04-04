# syntax=docker/dockerfile:1.4
FROM jauderho/dive:git AS dive

FROM aquasec/trivy:0.39.0 AS trivy

FROM goodwithtech/dockle:v0.4.11 AS dockle

FROM alpine:3.17 AS final

COPY --from=dive /usr/local/bin/dive /usr/local/bin/dive
COPY --from=dockle /usr/bin/dockle /usr/local/bin/dockle
COPY --from=trivy /usr/local/bin/trivy /usr/local/bin/trivy

RUN apk add --no-cache \
    "bash>5.2.12"

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
