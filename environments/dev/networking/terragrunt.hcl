# Development Environment - Networking Configuration
# This file configures the networking module for the development environment

# Include the root configuration
include "root" {
  path = find_in_parent_folders("root.hcl")
}

# Include the networking module
terraform {
  source = "../../../modules/networking"
}

# Environment-specific inputs
inputs = {
  # Environment
  environment = "dev"
  
  # VPC Configuration
  vpc_cidr = "10.0.0.0/16"
  
  # Subnet Configuration (smaller for dev)
  public_subnet_cidrs = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]
  
  private_subnet_cidrs = [
    "10.0.10.0/24",
    "10.0.20.0/24"
  ]
  
  database_subnet_cidrs = [
    "10.0.30.0/24",
    "10.0.40.0/24"
  ]
  
  # Cost optimization for development
  enable_nat_gateway = false  # Use NAT instances or no NAT for cost savings
  enable_s3_endpoint = true   # Enable S3 endpoint for cost savings
  enable_dynamodb_endpoint = true  # Enable DynamoDB endpoint for cost savings
  
  # Security settings
  enable_flow_logs = true
  flow_log_destination_type = "cloud-watch-logs"
  
  # Common tags
  common_tags = {
    Environment = "dev"
    CostCenter  = "development"
    Project     = "terraform-terragrunt-infrastructure"
    Owner       = "devops-team"
    ManagedBy   = "terragrunt"
    CreatedBy   = "terraform"
  }
}

# Dependencies
dependencies {
  paths = []
}