variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "instance_type" {
  type    = string
  default = "t3.medium"
}

variable "ami_id" {
  type    = string
  # Replace with a public Ubuntu 22.04 AMI for your region
  default = "REPLACE_WITH_UBUNTU_AMI"
}

variable "ssh_key_name" {
  type = string
}

variable "vpc_security_group_ids" {
  type    = list(string)
  default = []
}
