#!/bin/bash

set -e
# -e option causes the script to exit immediately if any command exits with a non-zero status, which is useful for catching errors early and preventing the script from continuing in an unexpected state.

# install reqired packages
sudo apt update
sudo apt install -y \
  build-essential \
  cmake \
  git \
  curl \
  python3 \
  python3-venv \
  python3-pip

# copy project files from the GitHub repo
git clone "${project_repo_url}" -b 001-local-setup /home/ubuntu/cppcicd