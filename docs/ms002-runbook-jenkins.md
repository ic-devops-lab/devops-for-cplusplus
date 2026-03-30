# Runbook — Jenkins on AWS (Terraform) and First CI Pipeline

## 1. Purpose

This runbook describes how to:
- provision a dedicated Jenkins VM in AWS using Terraform
- access Jenkins
- complete the minimal Jenkins setup
- create the first pipeline job
- run the initial CI pipeline

---

## 2. Infrastructure assumptions

The project uses:
- local or AWS Linux machine for development
- AWS + Terraform for infrastructure

Jenkins runs on a dedicated EC2 instance.

At minimum, the Jenkins VM should have enough resources for:
- Jenkins itself
- Java runtime
- Git operations
- compiling the C++ project
- running Python integration tests

A very small instance type is usually not comfortable for repeated C++ builds. Choose a VM size that supports a smoother CI workflow.

---

## 3. Provision Jenkins VM with Terraform

Example flow:

```bash
cd infra/terraform
terraform init
terraform plan
terraform apply
```

Expected result:
- EC2 instance for Jenkins
- security group allowing required access
- outputs showing how to connect to the machine and UI

At this stage, the Jenkins VM should ideally be provisioned with:
- Java
- Jenkins
- reqired Jenkins plugins
- Git
- Python 3
- python3-venv
- python3-pip
- CMake
- build-essential
- curl
- optional code quality tools such as `cppcheck` and `clang-format`

---

## 4. Access Jenkins

Copy the Jenkins instance IP addres from the output of the `terraform apply` command or from the AWS admin panel.

Open Jenkins in browser using the Jenkins instance address and port 8080.

Example:
```text
http://<jenkins-public-ip>:8080
```

Retrieve the initial admin password on the VM:

```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

Use that password to complete the initial login.

---

## 5. Minimal Jenkins setup

Recommended minimal setup:
- create the first admin user
- confirm Jenkins URL
- verify plugins are installed
- do not add extra global complexity yet

At this stage, keep Jenkins simple:
- one controller node
- one pipeline job
- pipeline from SCM
- no agents yet

This is intentional. The goal is to build a clean baseline first.

---

## 6. Jenkins plugins used in this project

### Pipeline
Purpose:
- enables Jenkinsfile support

Why it matters here:
- pipeline logic lives in the repository
- CI behavior becomes versioned and reviewable

### Git
Purpose:
- clones the source repository

Why it matters here:
- Jenkins needs repo access to build the project

### Credentials
Purpose:
- stores tokens, SSH keys, passwords

Why it matters here:
- needed if repository access is private
- becomes essential for later deployment steps

### Pipeline: Stage View
Purpose:
- shows stage-by-stage pipeline progress

Why it matters here:
- easier troubleshooting when a stage fails

### Blue Ocean
Purpose:
- provides a cleaner pipeline UI

Why it matters here:
- easier to understand stage flow
- easier to inspect failed runs
- useful for demos and learning

### Warnings Next Generation
Purpose:
- collects warnings and static analysis reports

Why it matters here:
- allows code quality checks to be visible in Jenkins
- useful for `cppcheck` and similar tools

### Timestamper

Purpose:
- adds timestamps to the console output of Jenkins jobs. For example:
```
21:51:15  Started by user anonymous
21:51:15  Building on my-jenkins-agent
21:51:17  Finished: SUCCESS
```

Why it matters here:
- better pipeline logging

---

## 7. Connect Jenkins to the repository

Create a pipeline job.

Recommended approach:
1. New Item
2. choose **Pipeline**
3. configure **Pipeline script from SCM**
4. SCM = Git
5. set repository URL
6. set credentials if needed
7. set script path to:
   `jenkins/Jenkinsfile`
8. set a specific branch is needed

This keeps pipeline logic inside the repository instead of embedding it in the Jenkins UI.

---

## 8. First pipeline behavior

The first pipeline should do only the following:

### Checkout
Clone the repository.

### Build
Run the existing build workflow:
```bash
./scripts/build.sh
```

### Unit tests
Run the C++ unit tests:
```bash
ctest --test-dir build --output-on-failure
```

### Integration tests
Run the Python integration tests:
```bash
pytest app/tests/integration -q
```

### Code quality
Run lightweight checks such as:
```bash
cppcheck ...
clang-format ...
```

### Package
Create an archive containing the built binary:
```bash
tar -czf build/echo_server.tar.gz build/echo_server
```

### Archive artifact
Store the package in Jenkins so it can be downloaded from the build page.

---

## 9. Verify success

A successful run should prove:

- Jenkins can access the repository
- the project builds on the Jenkins VM
- tests pass in CI
- code quality checks run
- the artifact is archived and downloadable

Things to verify in the Jenkins UI:
- console logs
- stage status
- artifact section
- Blue Ocean stage flow, if enabled

---

## 10. Troubleshooting

### Jenkins UI not reachable
Check:
```bash
sudo systemctl status jenkins
sudo ss -ltnp | grep 8080
```

Also verify:
- EC2 security group allows inbound access on 8080
- instance is reachable
- Jenkins finished booting

### Build fails
Check:
- required build tools are installed
- Jenkins user has access to the workspace
- the VM has enough CPU/RAM for the build

### Python tests fail
Check:
- Python dependencies are installed
- virtual environment strategy in pipeline is correct
- integration tests can launch the compiled binary

### Plugin functionality missing
Check:
- plugin installation logs
- Jenkins plugin manager
- whether Jenkins restart was needed after provisioning

---