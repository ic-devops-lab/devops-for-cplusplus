#!/usr/bin/env bash
set -euo pipefail

python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -r tools/python_helper/requirements.txt

echo "Bootstrap complete. Activate with: source .venv/bin/activate"
