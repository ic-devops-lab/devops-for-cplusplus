variable "ami" {
  description = "AMI ID for the instance"
  type        = string
  default = "ami-0ec10929233384c7f" # Ubuntu Server 24.04 LTS (HVM),EBS General Purpose (SSD) Volume Type
}

variable "instance_type" {
  description = "The instance type for the EC2 instance"
  type        = string
  default     = "m7i-flex.large" # 2 vCPUs, 8 GB RAM
}

variable "key_name" {
  description = "The name of the key pair to be used for the EC2 instance"
  type        = string
}

variable "vpc_security_group_ids" {
  description = "A list of security group IDs to associate with the EC2 instance"
  type        = list(string)
}

variable "availability_zone" {
  description = "The availability zone for the EC2 instance"
  type        = string
  default     = "us-east-1a"
}

variable "tags" {
  description = "A map of tags to assign to the EC2 instance"
  type        = map(string)
}

variable "user_data_script_name" {
  description = "The name of the user data script to be used for provisioning the EC2 instance"
  type        = string
}

variable "user_data_script_vars" {
  description = "A map of variables to be passed to the user data script template"
  type        = map(any)
  default = {}
}

variable "user_data_replace_on_change" {
  description = "Whether to replace the instance when the user data script changes"
  type        = bool
  default     = true
}

variable "disk_size" {
  description = "The size of the root EBS volume in GB"
  type        = number
  default     = 20
}