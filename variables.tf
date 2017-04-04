variable "aws_region" {}

variable "ec2_ami" {}

variable "manager_count" {}

variable "worker_count" {}

variable "manager_size" {
  default = "t2.micro"
}

variable "worker_size" {
  default = "t2.micro"
}

variable "key" {}
