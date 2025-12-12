terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# VPC Configuration
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Private subnets for DNS servers
resource "aws_subnet" "private" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${var.project_name}-private-subnet-${count.index + 1}"
  }
}

# Security group for DNS servers
resource "aws_security_group" "dns_server" {
  name        = "${var.project_name}-dns-sg"
  description = "Security group for private DNS server"
  vpc_id      = aws_vpc.main.id

  # DNS UDP from VPC
  ingress {
    description = "DNS UDP from VPC"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr]
  }

  # DNS TCP from VPC
  ingress {
    description = "DNS TCP from VPC"
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # SSH from VPC
  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Outbound to VPC
  egress {
    description = "Allow outbound to VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  # HTTPS for updates
  egress {
    description = "Allow HTTPS outbound"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP for updates
  egress {
    description = "Allow HTTP outbound"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-dns-sg"
  }
}

# IAM role for DNS servers
resource "aws_iam_role" "dns_server" {
  name = "${var.project_name}-dns-server-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-dns-role"
  }
}

resource "aws_iam_instance_profile" "dns_server" {
  name = "${var.project_name}-dns-server-profile"
  role = aws_iam_role.dns_server.name
}

resource "aws_iam_role_policy_attachment" "cloudwatch_logs" {
  role       = aws_iam_role.dns_server.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# DNS Server EC2 Instances
resource "aws_instance" "dns_server" {
  count                  = var.dns_server_count
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private[count.index % length(aws_subnet.private)].id
  vpc_security_group_ids = [aws_security_group.dns_server.id]
  iam_instance_profile   = aws_iam_instance_profile.dns_server.name
  
  associate_public_ip_address = false

  user_data = templatefile("${path.module}/user_data.sh", {
    dns_domain = var.dns_domain
    server_id  = count.index + 1
  })

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name = "${var.project_name}-dns-server-${count.index + 1}"
  }
}

# Network Load Balancer
resource "aws_lb" "dns_nlb" {
  name               = "${var.project_name}-dns-nlb"
  internal           = true
  load_balancer_type = "network"
  subnets            = aws_subnet.private[*].id

  enable_deletion_protection = false
  enable_cross_zone_load_balancing = true

  tags = {
    Name = "${var.project_name}-dns-nlb"
  }
}

# Target group for UDP DNS
resource "aws_lb_target_group" "dns_udp" {
  name     = "${var.project_name}-dns-udp-tg"
  port     = 53
  protocol = "UDP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
    port                = 53
    protocol            = "TCP"
  }

  tags = {
    Name = "${var.project_name}-dns-udp-tg"
  }
}

# Target group for TCP DNS
resource "aws_lb_target_group" "dns_tcp" {
  name     = "${var.project_name}-dns-tcp-tg"
  port     = 53
  protocol = "TCP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
    port                = 53
    protocol            = "TCP"
  }

  tags = {
    Name = "${var.project_name}-dns-tcp-tg"
  }
}

# Register servers with UDP target group
resource "aws_lb_target_group_attachment" "dns_udp" {
  count            = var.dns_server_count
  target_group_arn = aws_lb_target_group.dns_udp.arn
  target_id        = aws_instance.dns_server[count.index].id
  port             = 53
}

# Register servers with TCP target group
resource "aws_lb_target_group_attachment" "dns_tcp" {
  count            = var.dns_server_count
  target_group_arn = aws_lb_target_group.dns_tcp.arn
  target_id        = aws_instance.dns_server[count.index].id
  port             = 53
}

# Listener for UDP
resource "aws_lb_listener" "dns_udp" {
  load_balancer_arn = aws_lb.dns_nlb.arn
  port              = "53"
  protocol          = "UDP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.dns_udp.arn
  }
}

# Listener for TCP
resource "aws_lb_listener" "dns_tcp" {
  load_balancer_arn = aws_lb.dns_nlb.arn
  port              = "53"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.dns_tcp.arn
  }
}
