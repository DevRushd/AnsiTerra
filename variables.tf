variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}


variable "my_ip" {
  description = "Admin IP"
  type        = string
  sensitive = true
}

variable "instance_type" {
  description = "Instance type"
  type        = string
}

variable "key_pair" {
  description = "private key"
  type        = string
}