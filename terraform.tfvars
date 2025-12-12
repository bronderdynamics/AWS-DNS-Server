# Example Terraform variables file
# Copy this to terraform.tfvars and customize

aws_region            = "us-east-1"
project_name          = "private-dns"
vpc_cidr              = "10.0.0.0/16"
private_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
availability_zones    = ["us-east-1a", "us-east-1b", "us-east-1c"]
instance_type         = "t3.micro"
dns_server_count      = 3
dns_domain            = "internal.local"

# Update this AMI ID for your region
# Amazon Linux 2023 AMI IDs by region:
# us-east-1: ami-0453ec754f44f9a4a
# us-west-2: ami-0eb9d67c52f5c80e5
# eu-west-1: ami-0d940f23d527c3ab1
ami_id                = "ami-0453ec754f44f9a4a"
