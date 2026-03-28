output "devops_instance_public_ip" {
  description = "The public IP address of the DevOps EC2 instance"
  value       = aws_instance.devops_host.public_ip
}

# Write IPs to file for later cleanup
resource "local_file" "ips_to_remove" {
  filename = "${path.module}/ips_to_remove.txt"
  content  = <<-EOT
${aws_instance.devops_host.public_ip}
EOT

  depends_on = [
    aws_instance.devops_host,
  ]
}