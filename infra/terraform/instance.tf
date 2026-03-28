# ### DevOps environment instance
resource "aws_instance" "devops_host" {
  ami                    = var.devops_instance_ami
  instance_type          = var.devops_instance_type
  key_name               = aws_key_pair.devops_key_pair.key_name
  vpc_security_group_ids = [aws_security_group.devops_sg.id]
  availability_zone      = var.devops_instance_zone

  tags = local.devops_instance_tags

  user_data_base64 = base64encode(templatefile("${path.module}/provision/devops_host_setup.sh", {
    project_repo_url = "https://github.com/ic-devops-lab/devops-for-cplusplus"
  }))
}