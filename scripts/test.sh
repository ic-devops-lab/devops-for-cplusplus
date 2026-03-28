#!/usr/bin/env bash
set -euo pipefail

BUILD_DIR="${BUILD_DIR:-build}"
ctest --test-dir "$BUILD_DIR" --output-on-failure
pytest app/tests/integration -q
