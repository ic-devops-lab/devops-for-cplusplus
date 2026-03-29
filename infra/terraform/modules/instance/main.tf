resource "aws_instance" "vm" {
  ami = var.ami
  instance_type = var.instance_type
  key_name = var.key_name
  vpc_security_group_ids = var.vpc_security_group_ids
  availability_zone = var.availability_zone

  tags = var.tags

  user_data_base64 = base64encode(file("${path.module}/../../user_data/${var.user_data_script_name}"))
}