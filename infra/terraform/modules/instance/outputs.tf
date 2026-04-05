output "public_ip" {
  description = "The public IP of the created EC2 instance"
  value = aws_instance.vm.public_ip

  depends_on = [
    aws_instance.vm,
    aws_ec2_instance_state.vm_state
  ]
}