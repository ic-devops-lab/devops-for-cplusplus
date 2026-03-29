#!/usr/bin/env bash
set -euo pipefail

ARTIFACT_PATH="build/echo_server.tar.gz"

if [[ ! -f "build/echo_server" ]]; then
  echo "ERROR: build/echo_server not found. Build first."
  exit 1
fi

tar -czf "${ARTIFACT_PATH}" -C build echo_server

echo "Created artifact: ${ARTIFACT_PATH}"