resource "aws_security_group" "nautobot_sg" {
  name        = "nautobot-sg"
  description = "Allow SSH and Nautobot traffic"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "nautobot_vm" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.ssh_key_name
  vpc_security_group_ids = [aws_security_group.nautobot_sg.id]

  tags = {
    Name = "nautobot-poc"
  }
}

output "instance_public_ip" {
  value = aws_instance.nautobot_vm.public_ip
}
