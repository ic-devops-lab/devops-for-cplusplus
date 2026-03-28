resource "aws_key_pair" "devops_key_pair" {
  key_name   = "${var.project_prefix}-${var.devops_key_pair_name}"
  public_key = file("${local.secrets_dir}/${var.devops_key_pair_name}.pub")
}
