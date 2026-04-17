# Runbook — k3s Cluster Provisioning

This runbook provisions the Kubernetes execution layer used by Jenkins dynamic agents.

The result of this runbook should be:

- one EC2 instance running k3s
- Kubernetes API accessible from Jenkins
- kubeconfig exported and adjusted for Jenkins integration

---

## 1. Starting assumptions

This runbook assumes:

- Terraform is already used in the project
- a Jenkins VM already exists
- a SonarQube VM already exists
- AWS region is already chosen
- SSH key setup already exists
- you are extending the project from [Milestone 3]

This runbook adds only the **k3s VM** and its related security/routing pieces.

---

## 2. Recommended instance and networking

Recommended VM:

- instance type: `m7i-flex.large`
- OS: Ubuntu 24.04 LTS
- root disk: 20 GB gp3

Recommended access model:

- SSH (22/tcp) from your IP only
- Kubernetes API (6443/tcp) from Jenkins private IP or Jenkins security group only

If your current infrastructure is all in one VPC/subnet, keep k3s in the same subnet family unless you have a reason to isolate it further.

For simplisity in this repo k3s VM added to the deovps security group

---

## 3. Settings for locals.tf

Add this to [`terraform/locals.tf`](../infra/terraform/locals.tf):
```hcl
...
  devops_k3s_m_tags = {
    "Name"        = "${var.project_prefix}-devops-k3s-m"
    "Project"     = var.project_prefix
    "Environment" = "DevOps"
  }
...
```

---

## 4. Security group addition

We already have all internal traffic allowed within the devops security group (`devops_sg`) - see the `devops_sg_in_allow_all_internal` rule in the [`terraform/security_grp.tf`](../infra/terraform/security_grp.tf).

If you want to tighen up the security, create a separate group for k3s cluster and allow 22/tcp form home IP and 6443/tcp from the security goup the Jenkins VM belongs to.

---

## 5. k3s EC2 instance

Add the following or similar to [`terraform/instance.tf](../infra/terraform/instance.tf):
```hcl
...
module "devops_k3s_m" {
  source = "./modules/instance"

  key_name               = aws_key_pair.devops_key_pair.key_name
  vpc_security_group_ids = [aws_security_group.devops_sg.id]

  tags = local.devops_k3s_m_tags

  user_data_script_name = "k3s_setup.sh"

}
...
```

Important:
`user_data_replace_on_change = true` makes this VM much easier to rebuild predictably when bootstrap changes. It is set to `true` by default for [`instance` module](../infra/terraform/modules/instance/main.tf) used for provisioning EC2 instances in this lab.

---

## 6. k3s bootstrap script

Create:

`infra/terraform/userdata/k3s_setup.sh`

```bash
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
```

This script is intentionally minimal in this lab. It installs k3s to the instance and starts the service.

---

## 7. Terraform outputs

File: [`terraform/outputs.tf](../infra/terraform/outputs.tf)

Add output such as:

```hcl
output "devops_k3s_m_public_ip" {
  description = "The public IP address of the DevOps k3s master EC2 instance"
  value       = module.devops_k3s_m.public_ip
}

output "devops_k3s_m_private_ip" {
  description = "The private IP address of the DevOps k3s master EC2 instance"
  value       = module.devops_k3s_m.private_ip
}
```

And update `for_each` list and `depends_on` section for `track_ips` resource (used for cleanup):
```
...
  for_each = {
    devops_host   = module.devops_host.public_ip
    jenkins_srv   = module.jenkins_srv.public_ip
    sonarqube_srv = module.sonarqube_srv.public_ip
    devops_k3s_m = module.devops_k3s_m.public_ip
    # Later add more instances here:
    # app_server = aws_instance.app_server.public_ip
    # db_server = aws_instance.db_server.public_ip
  }
...
  depends_on = [
    module.devops_host,
    module.jenkins_srv,
    module.sonarqube_srv,
    module.devops_k3s_m    # Later add more instances here:
  ]
...
```

Use your project’s actual SSH username if different.

---

## 8. Apply Terraform

From your Terraform root:

```bash
terraform fmt
terraform init
terraform validate
terraform plan
terraform apply
```

Record:

- devops_k3s_m public IP
- devops_k3s_m private IP

You will need the private IP for kubeconfig and Jenkins configuration.

---

## 9. Verify k3s on the VM

SSH into the k3s VM and run:

```bash
sudo kubectl get nodes
sudo kubectl get pods -A
```

Expected:

- one node
- node status `Ready`
- system pods in `Running` state after initialization settles

If the node is not ready, inspect:

```bash
sudo journalctl -u k3s -n 100 --no-pager
sudo tail -n 100 /var/log/k3s-bootstrap.log
```

---

## 10. Export kubeconfig

Retrieve kubeconfig:

```bash
sudo cat /etc/rancher/k3s/k3s.yaml
```

Important:
This file usually points to `https://127.0.0.1:6443`.

That will **not** work for Jenkins on another VM.

Copy the kubeconfig content locally and replace:

```yaml
server: https://127.0.0.1:6443
```

with:

```yaml
server: https://<k3s-private-ip>:6443
```

where `<k3s-private-ip>` is the private IP of the k3s VM.

Save that adjusted file securely.
You will use it in Jenkins as a credential.

---

## 11. Validate API reachability from Jenkins VM

SSH into the Jenkins VM and test connectivity to k3s:

```bash
curl -k https://<k3s-private-ip>:6443/version
```

You should get a response from the Kubernetes API like this:
```
{
  "kind": "Status",
  "apiVersion": "v1",
  "metadata": {},
  "status": "Failure",
  "message": "Unauthorized",
  "reason": "Unauthorized",
  "code": 401
}
```
"Unauthorized" status is OK as we don't have k3s credentials on Jenkins controller yet.

If this fails, check:

- security group rules
- private IP correctness
- VPC/subnet routing
- whether k3s is listening

On the k3s VM, verify:

```bash
sudo ss -ltnp | grep 6443
```

---

## 12. Definition of done

This runbook is complete when:

- k3s VM exists
- k3s node is `Ready`
- adjusted kubeconfig is available
- Jenkins VM can reach the k3s API on port 6443

---