output "public_ip" {
  description = "The public IP of the created EC2 instance"
  value = aws_instance.vm.public_ip

  depends_on = [
    aws_instance.vm,
    aws_ec2_instance_state.vm_state
  ]
}

output "private_ip" {
  description = "The private IP of the created EC2 instance"
  value = aws_instance.vm.private_ip

  depends_on = [
    aws_instance.vm
  ]
}

output "instance_state" {
  description = "The EC2 instance state resource"
  value       = aws_ec2_instance_state.vm_state
}