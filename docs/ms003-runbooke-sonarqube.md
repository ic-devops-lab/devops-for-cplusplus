# Runbook — SonarQube Server on AWS

This runbook describes how to provision and configure a dedicated SonarQube server for the project.

It assumes:

- AWS infrastructure is managed with Terraform
- Jenkins already exists from Milestone 2
- SonarQube will run on a separate EC2 instance
- this setup is for a reproducible lab, not a hardened production environment

---

## 1. Goal

Provision a SonarQube server that Jenkins can use for C++ analysis and quality gates.

The result should be:

- SonarQube VM exists and is reachable
- SonarQube UI is available
- an admin password is set
- a project token can be created for Jenkins
- Jenkins can submit analysis and receive quality gate status

---

## 2. Recommended AWS shape

For this lab, keep the SonarQube VM simple but not too small.

Recommended baseline:

- Ubuntu 24.04 LTS
- 2 vCPU minimum
- 4 GB RAM minimum
- 20 GB disk minimum
- public IP for initial setup
- security group allowing:
  - 22/tcp from your IP
  - 9000/tcp from your IP

Keep the instance separate from Jenkins.

---

## 3. Terraform responsibilities

Terraform should:

- create the SonarQube EC2 instance
- create the security group
- attach a public IP
- pass a bootstrap script via `user_data`
- output:
  - public IP
  - SonarQube URL
  - SSH command

Recommended Terraform pattern:

- keep SonarQube in the same Terraform root for now
- use a dedicated `sonarqube_setup.sh`
- enable `user_data_replace_on_change = true`

That ensures setup changes force a fresh instance when needed.

---