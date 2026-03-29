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
- Git
- Python 3
- `python3-venv`
- `python3-pip`
- CMake
- build-essential
- curl
- optional code quality tools such as `cppcheck` and `clang-format`

---
