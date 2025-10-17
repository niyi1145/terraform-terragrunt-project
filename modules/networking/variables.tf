# Networking Module - Variables
# This file defines all input variables for the networking module

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
  validation {
    condition     = length(var.public_subnet_cidrs) >= 2
    error_message = "At least 2 public subnets are required for high availability."
  }
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24"]
  validation {
    condition     = length(var.private_subnet_cidrs) >= 2
    error_message = "At least 2 private subnets are required for high availability."
  }
}

variable "database_subnet_cidrs" {
  description = "CIDR blocks for database subnets"
  type        = list(string)
  default     = ["10.0.30.0/24", "10.0.40.0/24"]
  validation {
    condition     = length(var.database_subnet_cidrs) >= 2
    error_message = "At least 2 database subnets are required for high availability."
  }
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = true
}

variable "enable_s3_endpoint" {
  description = "Enable VPC endpoint for S3"
  type        = bool
  default     = false
}

variable "enable_dynamodb_endpoint" {
  description = "Enable VPC endpoint for DynamoDB"
  type        = bool
  default     = false
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = true
}

variable "flow_log_destination_type" {
  description = "Type of flow log destination (cloud-watch-logs, s3)"
  type        = string
  default     = "cloud-watch-logs"
  validation {
    condition     = contains(["cloud-watch-logs", "s3"], var.flow_log_destination_type)
    error_message = "Flow log destination type must be either 'cloud-watch-logs' or 's3'."
  }
}

variable "flow_log_s3_bucket" {
  description = "S3 bucket for VPC Flow Logs (required if flow_log_destination_type is s3)"
  type        = string
  default     = ""
}

variable "flow_log_s3_prefix" {
  description = "S3 prefix for VPC Flow Logs"
  type        = string
  default     = "vpc-flow-logs"
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support in the VPC"
  type        = bool
  default     = true
}

variable "enable_classiclink" {
  description = "Enable ClassicLink for the VPC"
  type        = bool
  default     = false
}

variable "enable_classiclink_dns_support" {
  description = "Enable ClassicLink DNS support for the VPC"
  type        = bool
  default     = false
}

variable "assign_generated_ipv6_cidr_block" {
  description = "Request an Amazon-provided IPv6 CIDR block with a /56 prefix length"
  type        = bool
  default     = false
}

variable "instance_tenancy" {
  description = "Tenancy of instances launched into the VPC"
  type        = string
  default     = "default"
  validation {
    condition     = contains(["default", "dedicated"], var.instance_tenancy)
    error_message = "Instance tenancy must be either 'default' or 'dedicated'."
  }
}

variable "enable_ipv6" {
  description = "Enable IPv6 support"
  type        = bool
  default     = false
}

variable "ipv6_cidr_block" {
  description = "IPv6 CIDR block for the VPC"
  type        = string
  default     = ""
}

variable "enable_network_acl" {
  description = "Enable Network ACLs"
  type        = bool
  default     = false
}

variable "network_acl_ingress_rules" {
  description = "List of ingress rules for Network ACL"
  type = list(object({
    rule_number = number
    protocol    = string
    rule_action = string
    cidr_block  = string
    from_port   = number
    to_port     = number
  }))
  default = []
}

variable "network_acl_egress_rules" {
  description = "List of egress rules for Network ACL"
  type = list(object({
    rule_number = number
    protocol    = string
    rule_action = string
    cidr_block  = string
    from_port   = number
    to_port     = number
  }))
  default = []
}

variable "enable_vpn_gateway" {
  description = "Enable VPN Gateway"
  type        = bool
  default     = false
}

variable "vpn_gateway_amazon_side_asn" {
  description = "Amazon side ASN for VPN Gateway"
  type        = number
  default     = 64512
}

variable "enable_transit_gateway" {
  description = "Enable Transit Gateway"
  type        = bool
  default     = false
}

variable "transit_gateway_id" {
  description = "ID of the Transit Gateway to attach to"
  type        = string
  default     = ""
}

variable "enable_customer_gateway" {
  description = "Enable Customer Gateway"
  type        = bool
  default     = false
}

variable "customer_gateway_ip" {
  description = "IP address of the Customer Gateway"
  type        = string
  default     = ""
}

variable "customer_gateway_bgp_asn" {
  description = "BGP ASN for Customer Gateway"
  type        = number
  default     = 65000
}

variable "enable_vpn_connection" {
  description = "Enable VPN Connection"
  type        = bool
  default     = false
}

variable "vpn_connection_type" {
  description = "Type of VPN connection"
  type        = string
  default     = "ipsec.1"
  validation {
    condition     = contains(["ipsec.1"], var.vpn_connection_type)
    error_message = "VPN connection type must be 'ipsec.1'."
  }
}

variable "enable_dhcp_options" {
  description = "Enable DHCP Options Set"
  type        = bool
  default     = false
}

variable "dhcp_options_domain_name" {
  description = "Domain name for DHCP options"
  type        = string
  default     = ""
}

variable "dhcp_options_domain_name_servers" {
  description = "List of domain name servers for DHCP options"
  type        = list(string)
  default     = ["AmazonProvidedDNS"]
}

variable "dhcp_options_ntp_servers" {
  description = "List of NTP servers for DHCP options"
  type        = list(string)
  default     = []
}

variable "dhcp_options_netbios_name_servers" {
  description = "List of NetBIOS name servers for DHCP options"
  type        = list(string)
  default     = []
}

variable "dhcp_options_netbios_node_type" {
  description = "NetBIOS node type for DHCP options"
  type        = number
  default     = 2
}

variable "enable_route53_resolver" {
  description = "Enable Route53 Resolver"
  type        = bool
  default     = false
}

variable "route53_resolver_rule_type" {
  description = "Type of Route53 Resolver rule"
  type        = string
  default     = "FORWARD"
  validation {
    condition     = contains(["FORWARD", "SYSTEM", "RECURSIVE"], var.route53_resolver_rule_type)
    error_message = "Route53 Resolver rule type must be one of: FORWARD, SYSTEM, RECURSIVE."
  }
}

variable "route53_resolver_rule_domain_name" {
  description = "Domain name for Route53 Resolver rule"
  type        = string
  default     = ""
}

variable "route53_resolver_rule_target_ips" {
  description = "List of target IPs for Route53 Resolver rule"
  type = list(object({
    ip   = string
    port = number
  }))
  default = []
}
