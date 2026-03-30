#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="/var/log/jenkins-bootstrap.log"
exec > >(tee "$LOG_FILE") 2>&1

echo "=== Jenkins bootstrap started ==="
date

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_SUSPEND=1

JENKINS_PLUGINS=(
  workflow-aggregator
  git
  credentials
  pipeline-stage-view
  blueocean
  warnings-ng
  timestamper
)

echo "=== Updating system packages ==="
apt-get update -y

echo "=== Installing base packages ==="
apt-get install -y \
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
install -d -m 0755 /etc/apt/keyrings

curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key \
  | tee /etc/apt/keyrings/jenkins-keyring.asc > /dev/null

echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" \
  | tee /etc/apt/sources.list.d/jenkins.list > /dev/null

apt-get update -y
apt-get install -y jenkins

echo "=== Preparing Jenkins home and plugin directories ==="
mkdir -p /var/lib/jenkins/tools
mkdir -p /var/lib/jenkins/plugins
chown -R jenkins:jenkins /var/lib/jenkins
chmod 755 /var/lib/jenkins
chmod 755 /var/lib/jenkins/tools
chmod 755 /var/lib/jenkins/plugins

echo "=== Installing Jenkins plugins (offline) ==="

# Stop Jenkins before modifying plugin directory
systemctl stop jenkins || true

PLUGIN_FILE="$(mktemp).txt"
printf "%s\n" "${JENKINS_PLUGINS[@]}" | tee "$PLUGIN_FILE" > /dev/null

PLUGIN_MANAGER_VERSION="2.14.0"
PLUGIN_MANAGER_JAR="/usr/local/bin/jenkins-plugin-manager.jar"
JENKINS_WAR="/usr/share/java/jenkins.war"

echo "Downloading Jenkins Plugin Manager Tool..."
curl -fsSL -o "$PLUGIN_MANAGER_JAR" \
  "https://github.com/jenkinsci/plugin-installation-manager-tool/releases/download/${PLUGIN_MANAGER_VERSION}/jenkins-plugin-manager-${PLUGIN_MANAGER_VERSION}.jar"

chmod 0644 "$PLUGIN_MANAGER_JAR"

if [[ ! -f "$JENKINS_WAR" ]]; then
  echo "ERROR: Jenkins WAR not found at $JENKINS_WAR"
  exit 1
fi

echo "Installing plugins into /var/lib/jenkins/plugins..."

mkdir -p /var/lib/jenkins/plugins

java -jar "$PLUGIN_MANAGER_JAR" \
  --war "$JENKINS_WAR" \
  --plugin-file "$PLUGIN_FILE" \
  --plugin-download-directory /var/lib/jenkins/plugins

rm -f "$PLUGIN_FILE"

chown -R jenkins:jenkins /var/lib/jenkins/plugins

echo "=== Plugins installed successfully ==="

echo "=== Enabling and starting Jenkins ==="
systemctl enable --now jenkins

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
  systemctl status --no-pager jenkins || true
  exit 1
fi

echo "=== Final status ==="
systemctl status --no-pager jenkins || true

echo "=== Installed plugins ==="
ls -1 /var/lib/jenkins/plugins || true

echo "=== Jenkins unlock / admin status ==="

JENKINS_PASSWORD_FILE="/var/lib/jenkins/secrets/initialAdminPassword"

if [[ -f "$JENKINS_PASSWORD_FILE" ]]; then
  echo "Initial admin password found in file:"
  cat "$JENKINS_PASSWORD_FILE"
else
  echo "No initialAdminPassword file found."
  echo "Jenkins may already be initialized. Check existing users or inspect logs with:"
  echo "  journalctl -u jenkins -n 100 --no-pager"
fi

echo "=== Jenkins bootstrap completed ==="
date

ls -l /var/lib/jenkins
echo "To move Jenkins, stop the service, archive /var/lib/jenkins, and restore it elsewhere"