# ### DevOps environment instances

# DevOps instance
module "devops_host" {
  source = "./modules/instance"

  key_name               = aws_key_pair.devops_key_pair.key_name
  vpc_security_group_ids = [aws_security_group.devops_sg.id]

  tags = local.devops_instance_tags

  user_data_script_name = "devops_host_setup.sh"
  user_data_script_vars = {
    project_repo_url = "https://github.com/ic-devops-lab/devops-for-cplusplus",
    branch_name      = "004-jenkins-agents"
  }
}

# Jenkins server (controller)
module "jenkins_srv" {
  source = "./modules/instance"

  key_name               = aws_key_pair.devops_key_pair.key_name
  vpc_security_group_ids = [aws_security_group.devops_sg.id]

  disk_size = 30

  tags = local.jenkins_srv_tags

  user_data_script_name = "jenkins_master_setup.sh"
}

# SonarQube server
module "sonarqube_srv" {
  source = "./modules/instance"

  key_name               = aws_key_pair.devops_key_pair.key_name
  vpc_security_group_ids = [aws_security_group.devops_sg.id]

  disk_size = 30

  tags = local.sonarqube_srv_tags

  user_data_script_name = "sonarqube_setup.sh"
}

# k3s master instance
module "devops_k3s_m" {
  source = "./modules/instance"

  key_name               = aws_key_pair.devops_key_pair.key_name
  vpc_security_group_ids = [aws_security_group.devops_sg.id]

  disk_size = 30

  tags = local.devops_k3s_m_tags

  user_data_script_name = "k3s_setup.sh"

}