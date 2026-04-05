#!/bin/bash
set -euo pipefail

LOG_FILE="/var/log/sonarqube-bootstrap.log"
exec > >(tee "$LOG_FILE") 2>&1
echo "=== SonarQube setup started ==="
date

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_SUSPEND=1

if [ -z "${POSTGRES_PW:-}" ]; then
  echo "Error: POSTGRES_PW environment variable is not set. Default password will be used."
  POSTGRES_PW="sonar123"
fi

# =============================================================================
# SonarQube Installation and Setup Script
# =============================================================================

# Section 1: System Configuration
# =============================================================================
echo "=== Configuring System Parameters ==="
cp /etc/sysctl.conf /root/sysctl.conf_backup
cat <<EOT> /etc/sysctl.conf
vm.max_map_count=262144
fs.file-max=65536
ulimit -n 65536
ulimit -u 4096
EOT

echo "=== Configuring Security Limits ==="
cp /etc/security/limits.conf /root/sec_limit.conf_backup
cat <<EOT> /etc/security/limits.conf
sonarqube   -   nofile   65536
sonarqube   -   nproc    4096
EOT

# Section 2: Install Java
# =============================================================================
echo "=== Installing Java 17 ==="
sudo apt-get update -y
sudo apt-get install openjdk-17-jdk -y
sudo update-alternatives --config java
java -version

# Section 3: Install and Configure PostgreSQL
# =============================================================================
echo "=== Installing PostgreSQL ==="
sudo apt update
wget -q https://www.postgresql.org/media/keys/ACCC4CF8.asc -O - | sudo apt-key add -
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" >> /etc/apt/sources.list.d/pgdg.list'
sudo apt install postgresql postgresql-contrib -y

echo "=== Starting PostgreSQL Service ==="
#sudo -u postgres psql -c "SELECT version();"
sudo systemctl enable --now postgresql.service


echo "=== Creating SonarQube Database and User ==="
sudo echo "postgres:${POSTGRES_PW}" | chpasswd
runuser -l postgres -c "createuser sonar"
sudo -i -u postgres psql -c "ALTER USER sonar WITH ENCRYPTED PASSWORD '${POSTGRES_PW}';"
sudo -i -u postgres psql -c "CREATE DATABASE sonarqube OWNER sonar;"
sudo -i -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE sonarqube to sonar;"
systemctl restart postgresql
netstat -tulpena | grep postgres

# Section 4: Install and Configure SonarQube
# =============================================================================
echo "=== Downloading and Installing SonarQube ==="
sudo mkdir -p /sonarqube/
cd /sonarqube/
sudo curl -O https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-9.9.8.100196.zip
sudo apt-get install zip -y
sudo unzip -o sonarqube-9.9.8.100196.zip -d /opt/
sudo mv /opt/sonarqube-9.9.8.100196/ /opt/sonarqube

echo "=== Setting up SonarQube User and Permissions ==="
sudo groupadd sonar
sudo useradd -c "SonarQube - User" -d /opt/sonarqube/ -g sonar sonar
sudo chown sonar:sonar /opt/sonarqube/ -R

echo "=== Configuring SonarQube Properties ==="
cp /opt/sonarqube/conf/sonar.properties /root/sonar.properties_backup
cat <<EOT> /opt/sonarqube/conf/sonar.properties
sonar.jdbc.username=sonar
sonar.jdbc.password="${POSTGRES_PW}"
sonar.jdbc.url=jdbc:postgresql://localhost/sonarqube
sonar.web.host=0.0.0.0
sonar.web.port=9000
sonar.web.javaAdditionalOpts=-server
sonar.search.javaOpts=-Xmx512m -Xms512m -XX:+HeapDumpOnOutOfMemoryError
sonar.log.level=INFO
sonar.path.logs=logs
EOT

echo "=== Creating SonarQube Systemd Service ==="
cat <<EOT> /etc/systemd/system/sonarqube.service
[Unit]
Description=SonarQube service
After=syslog.target network.target

[Service]
Type=forking
ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop
User=sonar
Group=sonar
Restart=always
LimitNOFILE=65536
LimitNPROC=4096

[Install]
WantedBy=multi-user.target
EOT

systemctl daemon-reload
systemctl enable --now sonarqube.service

# Section 5: Configure Nginx Reverse Proxy
# =============================================================================
echo "=== Installing and Configuring Nginx ==="
apt-get install nginx -y
rm -rf /etc/nginx/sites-enabled/default
rm -rf /etc/nginx/sites-available/default

cat <<EOT> /etc/nginx/sites-available/sonarqube
server{
  listen      80;
  server_name sonarqube.groophy.in;

  access_log  /var/log/nginx/sonar.access.log;
  error_log   /var/log/nginx/sonar.error.log;

  proxy_buffers 16 64k;
  proxy_buffer_size 128k;

  location / {
    proxy_pass  http://127.0.0.1:9000;
    proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504;
    proxy_redirect off;

    proxy_set_header    Host            \$host;
    proxy_set_header    X-Real-IP       \$remote_addr;
    proxy_set_header    X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header    X-Forwarded-Proto http;
  }
}
EOT

ln -s /etc/nginx/sites-available/sonarqube /etc/nginx/sites-enabled/sonarqube
systemctl enable nginx.service

# Section 6: Firewall and Reboot
# =============================================================================
echo "=== Configuring Firewall Rules ==="
sudo ufw allow 80,9000,9001/tcp

echo "=== Installation Complete - System reboot in 30 seconds ==="
sleep 30
reboot
