#!/usr/bin/env bash
set -euo pipefail

BUILD_DIR="${BUILD_DIR:-build}"
APP_BIND_ADDRESS="${APP_BIND_ADDRESS:-127.0.0.1}"
APP_PORT="${APP_PORT:-8080}"
APP_ENV="${APP_ENV:-dev}"
APP_NODE_ID="${APP_NODE_ID:-local-node}" \
  "$BUILD_DIR/echo_server"
