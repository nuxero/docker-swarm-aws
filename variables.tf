variable "aws_region" {
  type    = "string"
  default = "us-east-1"
}

variable "aws_az" {
  type    = "list"
  default = ["us-east-1a","us-east-1b","us-east-1c"]
}

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
