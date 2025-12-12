output "dns_nlb_endpoint" {
  description = "DNS endpoint for the Network Load Balancer (use this as your DNS resolver)"
  value       = aws_lb.dns_nlb.dns_name
}

output "dns_nlb_private_ips" {
  description = "Private IP addresses of the NLB endpoints"
  value       = aws_lb.dns_nlb.subnet_mapping[*].private_ipv4_address
}

output "dns_server_private_ips" {
  description = "Private IP addresses of all DNS servers"
  value       = aws_instance.dns_server[*].private_ip
}

output "dns_server_ids" {
  description = "Instance IDs of all DNS servers"
  value       = aws_instance.dns_server[*].id
}

output "nlb_id" {
  description = "ID of the Network Load Balancer"
  value       = aws_lb.dns_nlb.id
}

output "nlb_arn" {
  description = "ARN of the Network Load Balancer"
  value       = aws_lb.dns_nlb.arn
}

output "vpc_id" {
  description = "VPC ID where DNS server is deployed"
  value       = aws_vpc.main.id
}

output "security_group_id" {
  description = "Security group ID for DNS server"
  value       = aws_security_group.dns_server.id
}

output "dns_domain" {
  description = "DNS domain configured on the server"
  value       = var.dns_domain
}

output "test_dns_command" {
  description = "Command to test DNS from within VPC"
  value       = "dig @${aws_lb.dns_nlb.dns_name} ${var.dns_domain}"
}

output "test_dns_by_ip_commands" {
  description = "Commands to test each DNS server directly"
  value       = [for ip in aws_instance.dns_server[*].private_ip : "dig @${ip} ${var.dns_domain}"]
}
