variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name for resource tagging"
  type        = string
  default     = "private-dns"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "availability_zones" {
  description = "Availability zones for resources"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "dns_server_count" {
  description = "Number of DNS servers to deploy"
  type        = number
  default     = 3
}

variable "instance_type" {
  description = "EC2 instance type for DNS server"
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "AMI ID for DNS server (Amazon Linux 2023 recommended)"
  type        = string
  default     = "ami-0453ec754f44f9a4a" # Amazon Linux 2023 in us-east-1
}

variable "dns_domain" {
  description = "DNS domain name for the server to manage"
  type        = string
  default     = "internal.local"
}
