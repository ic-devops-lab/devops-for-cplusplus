# ### ### Security Group for DevOps environment
resource "aws_security_group" "devops_sg" {
  name        = "${var.project_prefix}-devops-sg"
  description = "Security group for DevOps environmentresources"
  tags = {
    "Name"        = "${var.project_prefix}-devops-sg",
    "Project"     = "${var.project_prefix}",
    "Environment" = "DevOps"
  }
}

# ### Ingress rules for DevOps security group

# Allow SSH access from home IP address
resource "aws_vpc_security_group_ingress_rule" "devops_sg_in_allow_ssh_from_home" {
  security_group_id = aws_security_group.devops_sg.id
  cidr_ipv4         = var.home_ip
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
}

# Allow HTTP 8080 access from anywhere (for Jenkins web interface)
resource "aws_vpc_security_group_ingress_rule" "devops_sg_in_allow_http_8080" {
  security_group_id = aws_security_group.devops_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 8080
  to_port           = 8080
  ip_protocol       = "tcp"
}

# Allow HTTP 9000 access from anywhere (for SonarQube web interface)
resource "aws_vpc_security_group_ingress_rule" "devops_sg_in_allow_http_9000" {
  security_group_id = aws_security_group.devops_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 9000
  to_port           = 9000
  ip_protocol       = "tcp"
}

# Allow all ingress traffice from the security group itself (for inter-instance communication)
resource "aws_vpc_security_group_ingress_rule" "devops_sg_in_allow_all_internal" {
  security_group_id            = aws_security_group.devops_sg.id
  referenced_security_group_id = aws_security_group.devops_sg.id
  from_port                    = 0
  to_port                      = 0
  ip_protocol                  = "-1"
}

# Allow all egress traffic from the security group (for outbound internet access)
resource "aws_vpc_security_group_egress_rule" "devops_sg_eg_allow_all" {
  security_group_id = aws_security_group.devops_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}