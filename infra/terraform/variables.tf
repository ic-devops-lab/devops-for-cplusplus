variable "project_region" {
  description = "The region to create the project's resources in"
  type        = string
  default     = "us-east-1"
}

variable "project_prefix" {
  description = "The prefix to be used for naming the project's resources"
  type        = string
  default     = "cppcicd"
}

variable "home_ip" {
  description = "The home IP address for SSH access"
  type        = string
  # Set your real home IP in terraform.tfvars file, e.g., home_ip = "99.99.99.199/32"
}

# ### Key Pair for EC2 instances
variable "devops_key_pair_name" {
  description = "The name of the key pair to be used for EC2 instances"
  type        = string
  default     = "devopskeypair"
}
