# Local Runbbok

This document contains the instructions of how to build, test and run the project locally

## Prerequisits

- configured devops environment
  - option 1: [local setup](./runbook-ms001.md)
  - option 2 (***recommended**): [devops VM on AWS](./runbook-tf-ms001.md)

## Check the project scripts

From the project's root folder:

1. Create and activate **Python virtual environment** and install app's **Python dependencies**
```bash
./scripts/bootstrap.sh
source .venv/bin/activate
```
2. **Build the C++ app**
```bash
./scripts/build.sh
```
3. **Test**
```bash
source .venv/bin/activate
./scripts/test.sh
```
4a. **Run locally (without systemd)**
```bash
./scripts/run_local.sh
curl http://127.0.0.1:8080/health
curl http://127.0.0.1:8080/version
curl -X POST http://127.0.0.1:8080/echo -H 'Content-Type: application/json' -d '{"message": "hello"}'
```
4b. **Running the application as a systemd service (Recommended)**

In addition to running the application locally, it can be installed and managed as a Linux service using systemd.

This better reflects real deployment scenarios.

***Install or update the service***

After building the application:
```bash
./scripts/build.sh
./scripts/install_service.sh
```

This simulates a production-like deployment model.

***Manage the service***

Use the helper script:
```
./scripts/service_control.sh <command>
```

Available commands:
```
start
stop
restart
status
logs
enable
disable
```

Examples:
```
./scripts/service_control.sh status
./scripts/service_control.sh logs
```

Or use systemctl directly:
```
sudo systemctl status app.service
sudo systemctl restart app.service
```

***Verify the service***

Once running:
```
curl http://127.0.0.1:8080/health
curl http://127.0.0.1:8080/version
```

Viewing logs
```
journalctl -u app.service -f
```

***Troubleshooting***

If the service fails to start:
1. Check status:
```
systemctl status app.service
```
2. Inspect logs:
```
journalctl -u app.service -n 50
```
3. Verify binary exists:
```
ls -l /opt/echo-app/echo_server
```
4. Verify configuration:
```
cat /etc/echo-app/app.env
```