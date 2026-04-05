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

  jenkins_srv_tags = {
    "Name"        = "${var.project_prefix}-jenkins-srv"
    "Project"     = var.project_prefix
    "Environment" = "DevOps"
  }

  sonarqube_srv_tags = {
    "Name"        = "${var.project_prefix}-sonarqube-srv"
    "Project"     = var.project_prefix
    "Environment" = "DevOps"
  }
}