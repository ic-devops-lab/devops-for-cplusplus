locals {
  project_tags = {
    "Project"     = var.project_prefix
    "Environment" = "Development"
  }

  secrets_dir = "${path.module}/.secrets"

  devops_instance_tags = {
    "Name"        = "${var.project_prefix}-devops-host"
    "Project"     = var.project_prefix
    "Environment" = "DevOps"
  }
}