# Declaring the variables. The values will be present in "tfvars" file

variable "aws_access_key" {}

variable "aws_secret_key" {}

variable "region" {}

data "aws_availability_zones" "available" {}

variable "azs" {
  type = "list"
  default = [ "us-east-2a" , "us-east-2b" ]
}

variable "instance_type" {}

variable "ami_id" {
  type = "map"
}

variable key_name {}

variable "pub_key" {}

variable "vpc_cidr_range" {}

variable "pubsubs_cidr_range" {
  type = "map"
}

variable "prisubs_cidr_range" {
  type = "map"
}
	