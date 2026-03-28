output "devops_instance_public_ip" {
  description = "The public IP address of the DevOps EC2 instance"
  value       = aws_instance.devops_host.public_ip
}

# Track IPs for all instances - scalable with for_each
resource "null_resource" "track_ips" {
  for_each = {
    devops_host = aws_instance.devops_host.public_ip
    # Later add more instances here:
    # app_server = aws_instance.app_server.public_ip
    # db_server = aws_instance.db_server.public_ip
  }

  provisioner "local-exec" {
    command = "grep -q '^${each.value}$' ${path.module}/ips_to_remove.txt 2>/dev/null || echo '${each.value}' >> ${path.module}/ips_to_remove.txt"
  }

  triggers = {
    public_ip = each.value
  }

  depends_on = [aws_instance.devops_host]
}

# Cleanup known_hosts when destroying
resource "null_resource" "cleanup_on_destroy" {
  provisioner "local-exec" {
    when    = destroy
    command = "bash -c 'while IFS= read -r ip; do ssh-keygen -R \"$ip\" 2>/dev/null && echo \"Removed $ip from known_hosts\"; done < ${path.module}/ips_to_remove.txt; rm -f ${path.module}/ips_to_remove.txt'"
  }
}