output "instance_public_ip" {
  value = aws_instance.nautobot_vm.public_ip
}
