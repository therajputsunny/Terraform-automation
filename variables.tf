variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Name of an existing EC2 SSH key pair"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH into the instance"
  type        = string
  default     = "0.0.0.0/0" # tighten this to your own IP, e.g. "203.0.113.5/32"
}

variable "instance_name" {
  description = "Name tag for the EC2 instance"
  type        = string
  default     = "ubuntu-ec2-instance"
}
