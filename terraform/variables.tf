variable "aws_region" {
  type    = string
  default = "eu-north-1"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"   # ✅ better CPU & RAM for Nautobot
}

variable "ami_id" {
  type    = string
  # ✅ Latest Ubuntu 22.04 LTS for eu-north-1 (HVM)
  default = "ami-0a716d3f3b16d290c"
}

variable "ssh_key_name" {
  type    = string
  # ✅ Must match the key pair name uploaded to AWS
  default = "NaC"
}

variable "vpc_security_group_ids" {
  type    = list(string)
  # ✅ Will be created automatically by Terraform usually
  default = []
}
