#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

echo ""
echo "[container-structure-test]"
container-structure-test version

echo ""
echo "[dive]"
dive --version

echo ""
echo "[dockle]"
dockle --version

echo ""
echo "[trivy]"
trivy --config=false version
