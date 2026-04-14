#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="/var/log/k3s-bootstrap.log"
exec > >(tee "$LOG_FILE") 2>&1

echo "=== k3s bootstrap started ==="
date

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_SUSPEND=1

apt-get update -y
apt-get install -y   ca-certificates   curl

curl -sfL https://get.k3s.io | sh -

systemctl enable --now k3s

echo "=== Waiting for k3s node to become ready ==="
for i in {1..30}; do
  if kubectl get nodes >/dev/null 2>&1; then
    echo "k3s is responding"
    break
  fi
  echo "Waiting for k3s... ($i/30)"
  sleep 5
done

echo "=== k3s bootstrap completed ==="
date