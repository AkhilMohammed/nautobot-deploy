variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "instance_type" {
  type    = string
  default = "t3.medium"   # ✅ better CPU & RAM for Nautobot
}

variable "ami_id" {
  type    = string
  # ✅ Latest Ubuntu 22.04 LTS for ap-south-1 (HVM)
  default = "ami-0f58b397bc5c1f2e8"
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
