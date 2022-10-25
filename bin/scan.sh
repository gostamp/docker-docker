#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

APP_REGISTRY="${APP_REGISTRY:?}"
APP_NAME="${APP_NAME:?}"
APP_TAG="${APP_TAG?}"

image="${APP_REGISTRY}/${APP_NAME}:${APP_TAG}"

echo ""
echo "[test] trivy"
trivy image --format sarif --output trivy.sarif "${image}"

echo ""
echo "[test] dockle"
dockle --format sarif --output dockle.sarif "${image}"

echo ""
echo "DONE"
echo ""
