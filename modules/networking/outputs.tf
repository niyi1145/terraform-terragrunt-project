# Networking Module - Outputs
# This file defines all output values for the networking module

# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_arn" {
  description = "ARN of the VPC"
  value       = aws_vpc.main.arn
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "vpc_default_security_group_id" {
  description = "ID of the default security group"
  value       = aws_vpc.main.default_security_group_id
}

output "vpc_default_network_acl_id" {
  description = "ID of the default network ACL"
  value       = aws_vpc.main.default_network_acl_id
}

output "vpc_default_route_table_id" {
  description = "ID of the default route table"
  value       = aws_vpc.main.default_route_table_id
}

output "vpc_ipv6_association_id" {
  description = "Association ID for the IPv6 CIDR block"
  value       = aws_vpc.main.ipv6_association_id
}

output "vpc_ipv6_cidr_block" {
  description = "IPv6 CIDR block"
  value       = aws_vpc.main.ipv6_cidr_block
}

output "vpc_owner_id" {
  description = "Owner ID of the VPC"
  value       = aws_vpc.main.owner_id
}

# Internet Gateway Outputs
output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "internet_gateway_arn" {
  description = "ARN of the Internet Gateway"
  value       = aws_internet_gateway.main.arn
}

# Subnet Outputs
output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "public_subnet_arns" {
  description = "ARNs of the public subnets"
  value       = aws_subnet.public[*].arn
}

output "public_subnet_cidr_blocks" {
  description = "CIDR blocks of the public subnets"
  value       = aws_subnet.public[*].cidr_block
}

output "public_subnet_availability_zones" {
  description = "Availability zones of the public subnets"
  value       = aws_subnet.public[*].availability_zone
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "private_subnet_arns" {
  description = "ARNs of the private subnets"
  value       = aws_subnet.private[*].arn
}

output "private_subnet_cidr_blocks" {
  description = "CIDR blocks of the private subnets"
  value       = aws_subnet.private[*].cidr_block
}

output "private_subnet_availability_zones" {
  description = "Availability zones of the private subnets"
  value       = aws_subnet.private[*].availability_zone
}

output "database_subnet_ids" {
  description = "IDs of the database subnets"
  value       = aws_subnet.database[*].id
}

output "database_subnet_arns" {
  description = "ARNs of the database subnets"
  value       = aws_subnet.database[*].arn
}

output "database_subnet_cidr_blocks" {
  description = "CIDR blocks of the database subnets"
  value       = aws_subnet.database[*].cidr_block
}

output "database_subnet_availability_zones" {
  description = "Availability zones of the database subnets"
  value       = aws_subnet.database[*].availability_zone
}

# NAT Gateway Outputs
output "nat_gateway_ids" {
  description = "IDs of the NAT Gateways"
  value       = aws_nat_gateway.main[*].id
}

output "nat_gateway_public_ips" {
  description = "Public IPs of the NAT Gateways"
  value       = aws_eip.nat[*].public_ip
}

output "nat_gateway_private_ips" {
  description = "Private IPs of the NAT Gateways"
  value       = aws_nat_gateway.main[*].private_ip
}

# Elastic IP Outputs
output "nat_eip_ids" {
  description = "IDs of the Elastic IPs for NAT Gateways"
  value       = aws_eip.nat[*].id
}

output "nat_eip_public_ips" {
  description = "Public IPs of the Elastic IPs for NAT Gateways"
  value       = aws_eip.nat[*].public_ip
}

# Route Table Outputs
output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "IDs of the private route tables"
  value       = aws_route_table.private[*].id
}

output "database_route_table_id" {
  description = "ID of the database route table"
  value       = aws_route_table.database.id
}

# Security Group Outputs
output "security_group_ids" {
  description = "IDs of the security groups"
  value = {
    web_sg_id      = aws_security_group.web.id
    app_sg_id      = aws_security_group.app.id
    database_sg_id = aws_security_group.database.id
  }
}

output "security_group_arns" {
  description = "ARNs of the security groups"
  value = {
    web_sg_arn      = aws_security_group.web.arn
    app_sg_arn      = aws_security_group.app.arn
    database_sg_arn = aws_security_group.database.arn
  }
}

output "web_security_group_id" {
  description = "ID of the web security group"
  value       = aws_security_group.web.id
}

output "app_security_group_id" {
  description = "ID of the application security group"
  value       = aws_security_group.app.id
}

output "database_security_group_id" {
  description = "ID of the database security group"
  value       = aws_security_group.database.id
}

# VPC Endpoint Outputs
output "s3_vpc_endpoint_id" {
  description = "ID of the S3 VPC endpoint"
  value       = var.enable_s3_endpoint ? aws_vpc_endpoint.s3[0].id : null
}

output "s3_vpc_endpoint_arn" {
  description = "ARN of the S3 VPC endpoint"
  value       = var.enable_s3_endpoint ? aws_vpc_endpoint.s3[0].arn : null
}

output "dynamodb_vpc_endpoint_id" {
  description = "ID of the DynamoDB VPC endpoint"
  value       = var.enable_dynamodb_endpoint ? aws_vpc_endpoint.dynamodb[0].id : null
}

output "dynamodb_vpc_endpoint_arn" {
  description = "ARN of the DynamoDB VPC endpoint"
  value       = var.enable_dynamodb_endpoint ? aws_vpc_endpoint.dynamodb[0].arn : null
}

# Availability Zones Output
output "availability_zones" {
  description = "List of availability zones used"
  value       = data.aws_availability_zones.available.names
}

output "availability_zone_count" {
  description = "Number of availability zones used"
  value       = length(data.aws_availability_zones.available.names)
}

# Network ACL Outputs (if enabled)
output "network_acl_id" {
  description = "ID of the network ACL"
  value       = null  # Not implemented in main.tf
}

# VPN Gateway Outputs (if enabled)
output "vpn_gateway_id" {
  description = "ID of the VPN Gateway"
  value       = null  # Not implemented in main.tf
}

# Transit Gateway Outputs (if enabled)
output "transit_gateway_attachment_id" {
  description = "ID of the Transit Gateway attachment"
  value       = null  # Not implemented in main.tf
}

# Customer Gateway Outputs (if enabled)
output "customer_gateway_id" {
  description = "ID of the Customer Gateway"
  value       = null  # Not implemented in main.tf
}

# VPN Connection Outputs (if enabled)
output "vpn_connection_id" {
  description = "ID of the VPN Connection"
  value       = null  # Not implemented in main.tf
}

# DHCP Options Outputs (if enabled)
output "dhcp_options_id" {
  description = "ID of the DHCP Options Set"
  value       = null  # Not implemented in main.tf
}

# Route53 Resolver Outputs (if enabled)
output "route53_resolver_rule_id" {
  description = "ID of the Route53 Resolver rule"
  value       = null  # Not implemented in main.tf
}

# Summary Outputs
output "network_summary" {
  description = "Summary of the network configuration"
  value = {
    vpc_id                = aws_vpc.main.id
    vpc_cidr              = aws_vpc.main.cidr_block
    public_subnets        = length(aws_subnet.public)
    private_subnets       = length(aws_subnet.private)
    database_subnets      = length(aws_subnet.database)
    nat_gateways          = var.enable_nat_gateway ? length(aws_nat_gateway.main) : 0
    availability_zones    = length(data.aws_availability_zones.available.names)
    security_groups       = 3
    vpc_endpoints         = (var.enable_s3_endpoint ? 1 : 0) + (var.enable_dynamodb_endpoint ? 1 : 0)
  }
}

# Cost Estimation Outputs
output "estimated_monthly_cost" {
  description = "Estimated monthly cost for networking resources"
  value = {
    nat_gateway_cost     = var.enable_nat_gateway ? length(aws_nat_gateway.main) * 45.60 : 0
    eip_cost            = var.enable_nat_gateway ? length(aws_eip.nat) * 3.65 : 0
    vpc_endpoint_cost   = ((var.enable_s3_endpoint ? 1 : 0) + (var.enable_dynamodb_endpoint ? 1 : 0)) * 7.30
    total_estimated_cost = 0  # Simplified for now
  }
}
