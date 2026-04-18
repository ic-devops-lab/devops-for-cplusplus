output "devops_instance_public_ip" {
  description = "The public IP address of the DevOps EC2 instance"
  value       = module.devops_host.public_ip
  depends_on  = [module.devops_host, module.devops_host.instance_state]
}

output "jenkins_srv_public_ip" {
  description = "The public IP address of the Jenkins EC2 instance"
  value       = module.jenkins_srv.public_ip
  depends_on  = [module.jenkins_srv, module.jenkins_srv.instance_state]

}

output "jenkins_srv_private_ip" {
  description = "The private IP address of the Jenkins EC2 instance"
  value       = module.jenkins_srv.private_ip
  depends_on  = [module.jenkins_srv]

}

output "sonarqube_srv_public_ip" {
  description = "The public IP address of the SonarQube EC2 instance"
  value       = module.sonarqube_srv.public_ip
  depends_on  = [module.sonarqube_srv, module.sonarqube_srv.instance_state]
}

output "sonarqube_srv_private_ip" {
  description = "The private IP address of the SonarQube EC2 instance"
  value       = module.sonarqube_srv.private_ip
  depends_on  = [module.sonarqube_srv]
}

output "devops_k3s_m_public_ip" {
  description = "The public IP address of the DevOps k3s master EC2 instance"
  value       = module.devops_k3s_m.public_ip
  depends_on  = [module.devops_k3s_m, module.devops_k3s_m.instance_state]
}

output "devops_k3s_m_private_ip" {
  description = "The private IP address of the DevOps k3s master EC2 instance"
  value       = module.devops_k3s_m.private_ip
  depends_on  = [module.devops_k3s_m]
}

output "project_urls" {
  description = "URLs to access the deployed services"
  value = {
    jenkins_public_url   = "http://${module.jenkins_srv.public_ip}:8080"
    jenkins_private_url  = "http://${module.jenkins_srv.private_ip}:8080"
    sonarqube_public_url = "http://${module.sonarqube_srv.public_ip}:9000"
    sonarqube_private_url = "http://${module.sonarqube_srv.private_ip}:9000"
  }
  depends_on = [
    module.jenkins_srv.instance_state,
    module.sonarqube_srv.instance_state
   ]
}

# Track IPs for all instances - scalable with for_each
resource "null_resource" "track_ips" {
  for_each = {
    devops_host   = module.devops_host.public_ip
    jenkins_srv   = module.jenkins_srv.public_ip
    sonarqube_srv = module.sonarqube_srv.public_ip
    devops_k3s_m  = module.devops_k3s_m.public_ip
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

  depends_on = [
    module.devops_host.instance_state,
    module.jenkins_srv.instance_state,
    module.sonarqube_srv.instance_state,
    module.devops_k3s_m.instance_state # Later add more instances here:
  ]
}

# Cleanup known_hosts when destroying
resource "null_resource" "cleanup_on_destroy" {
  provisioner "local-exec" {
    when    = destroy
    command = "bash -c 'while IFS= read -r ip; do ssh-keygen -R \"$ip\" 2>/dev/null && echo \"Removed $ip from known_hosts\"; done < ${path.module}/ips_to_remove.txt; rm -f ${path.module}/ips_to_remove.txt'"
  }
}