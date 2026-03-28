# Milestone 1 Runbook

## 1. Prerequisites

On Ubuntu/Debian, install:
```
sudo apt update
sudo apt install -y \
  build-essential \
  cmake \
  git \
  curl \
  python3 \
  python3-venv \
  python3-pip
```

## Clone the Lab repo

If you haven't done it yet:
```bash
cd <path-to-your-projects-storage-folder>
git clone -b 001-local-setup https://github.com/ic-devops-lab/devops-for-cplusplus

# make the project's bash scripts executable
sudo chmod +x /home/ubuntu/cppcicd/scripts/*.sh
```

## Build, Test, Install, Run the app

Follow these [instructions](./runbook-local.md)