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

## 4. Server installation strategy

For this milestone we use a provision script ([sonarqube_setup.sh](../infra/terraform/user_data/sonarqube_setup.sh)) that:

- installs Java
- installs PostgresQL and creates a database and db user for SonarQube
- installs and configures SonarQube
- installs and configures nginx as a reverse proxy for SonarQube service
- exposes port 9000

This keeps the milestone focused on integration rather than OS-level package management.

---

## 5. Terraform wiring example

Example instance block:

```hcl
resource "aws_instance" "sonarqube" {
  ami                         = var.ubuntu_ami_id
  instance_type               = var.sonarqube_instance_type
  subnet_id                   = aws_subnet.main.id
  vpc_security_group_ids      = [aws_security_group.sonarqube.id]
  key_name                    = var.key_name
  user_data                   = file("${path.module}/userdata/sonarqube_setup.sh")
  user_data_replace_on_change = true

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name = "sonarqube"
  }
}
```

In out lab VMs are created using local module (check infra/terraform/modules/instance)

---

## 6. Apply infrastructure

From the Terraform root:

```bash
terraform init
terraform plan
terraform apply
```

After apply, note the SonarQube public IP or URL output.

---

## 7. Verify the server

Use browser:

```text
http://<sonarqube-public-ip>:9000
```

Optional API check from your machine:

```bash
curl http://<sonarqube-public-ip>:9000/api/system/status
```

You want the service to become available before moving on to Jenkins integration.

---

## 8. First login

Default SonarQube credentials are commonly:

- username: `admin`
- password: `admin`

At first login, change the password immediately.

For this lab, store the new password safely outside the repository.

---

## 9. Create a project token for Jenkins

In SonarQube UI:

1. Log in as admin
2. Go to your account / security settings
3. Create a token for Jenkins
4. Save it securely

This token will later be added in Jenkins credentials.

---

## 10. Create or prepare the project in SonarQube

You can either:

- let the scanner create the project on first analysis, depending on server settings
- or create the project manually in the UI first

For a lab project, manual creation is often clearer.

Suggested project key:
- `devops-for-cplusplus`

Suggested project name:
- `devops-for-cplusplus`

---

## 11. Troubleshooting

### SonarQube UI not reachable

1. Chek the service on VM
```
sudo systemctl status --no-pager sonarqube
sudo journalctl -u sonarqube -n 100
```
2. Also verify the EC2 security group allows port 9000 from your IP.

### Server is slow to start
This is normal on smaller VMs. SonarQube can take some time to initialize.

---

## 13. Definition of done

The server side is ready when:

- SonarQube is reachable on port 9000
- you can log in
- admin password has been changed
- Jenkins token has been created
- the instance can be rebuilt with Terraform
