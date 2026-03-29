#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="/var/log/jenkins-bootstrap.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "=== Jenkins bootstrap started ==="
date

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

JENKINS_PLUGINS=(
  workflow-aggregator
  git
  credentials
  pipeline-stage-view
  blueocean
  warnings-ng
)

echo "=== Updating system packages ==="
sudo apt update -y

echo "=== Installing base packages ==="
sudo apt install -y \
  ca-certificates \
  curl \
  gnupg \
  lsb-release \
  software-properties-common \
  unzip \
  git \
  jq \
  fontconfig \
  openjdk-21-jdk \
  build-essential \
  cmake \
  cppcheck \
  clang-format \
  python3 \
  python3-venv \
  python3-pip

echo "=== Verifying key tools ==="
java -version
git --version
cmake --version
python3 --version
pip3 --version
cppcheck --version
clang-format --version

echo "=== Installing Jenkins LTS ==="
sudo install -d -m 0755 /etc/apt/keyrings

curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key \
  | sudo tee /etc/apt/keyrings/jenkins-keyring.asc > /dev/null

echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" \
  | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

sudo apt update -y
sudo apt install -y jenkins

echo "=== Ensuring Jenkins directories exist ==="
sudo mkdir -p /var/lib/jenkins/tools
sudo mkdir -p /var/lib/jenkins/plugins
sudo chown -R jenkins:jenkins /var/lib/jenkins
sudo chmod 755 /var/lib/jenkins
sudo chmod 755 /var/lib/jenkins/tools
sudo chmod 755 /var/lib/jenkins/plugins

echo "=== Stopping Jenkins before plugin installation ==="
sudo systemctl stop jenkins || true

echo "=== Installing Jenkins plugins ==="
PLUGIN_FILE="$(mktemp).txt"
printf "%s\n" "${JENKINS_PLUGINS[@]}" | sudo tee "$PLUGIN_FILE" > /dev/null

PLUGIN_MANAGER_VERSION="2.14.0"
PLUGIN_MANAGER_JAR="/usr/local/bin/jenkins-plugin-manager.jar"

sudo curl -fsSL -o "$PLUGIN_MANAGER_JAR" \
  "https://github.com/jenkinsci/plugin-installation-manager-tool/releases/download/${PLUGIN_MANAGER_VERSION}/jenkins-plugin-manager-${PLUGIN_MANAGER_VERSION}.jar"

sudo chmod 0644 "$PLUGIN_MANAGER_JAR"

sudo mkdir -p /var/lib/jenkins/plugins

sudo java -jar "$PLUGIN_MANAGER_JAR" \
  --war /usr/share/java/jenkins.war \
  --plugin-file "$PLUGIN_FILE" \
  --plugin-download-directory /var/lib/jenkins/plugins

rm -f "$PLUGIN_FILE"

sudo chown -R jenkins:jenkins /var/lib/jenkins/plugins

echo "=== Enabling and starting Jenkins ==="
sudo systemctl enable --now jenkins

echo "=== Waiting for Jenkins to become available ==="
JENKINS_READY=0
for i in {1..30}; do
  if curl -fsS http://127.0.0.1:8080/login > /dev/null; then
    echo "Jenkins is up"
    JENKINS_READY=1
    break
  fi
  echo "Waiting for Jenkins... ($i/30)"
  sleep 5
done

if [[ "$JENKINS_READY" -ne 1 ]]; then
  echo "ERROR: Jenkins did not become ready in time"
  sudo systemctl status --no-pager jenkins || true
  exit 1
fi

echo "=== Final status ==="
systemctl status --no-pager jenkins || true

echo "=== Installed plugins ==="
ls -1 /var/lib/jenkins/plugins || true

echo "=== Initial admin password ==="
sudo cat /var/lib/jenkins/secrets/initialAdminPassword || true

echo "=== Jenkins bootstrap completed ==="
date

ls -l /var/lib/jenkins
echo "To move Jenkins, stop the service, archive /var/lib/jenkins, and restore it elsewhere"