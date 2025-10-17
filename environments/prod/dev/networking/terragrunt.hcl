# Development Environment - Networking Configuration
# This file configures the networking module for the development environment

# Include the root terragrunt.hcl configuration
include "root" {
  path = find_in_parent_folders()
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

# Generate backend configuration
remote_state {
  backend = "s3"
  config = {
    bucket         = "terraform-terragrunt-state-${get_aws_account_id()}"
    key            = "dev/networking/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-terragrunt-locks"
  }
  
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

# Generate provider configuration
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  
  default_tags {
    tags = {
      Environment = "dev"
      Project     = "terraform-terragrunt-infrastructure"
      ManagedBy   = "terragrunt"
      Owner       = "devops-team"
      CreatedBy   = "terraform"
    }
  }
}
EOF
}

# Local values
locals {
  environment = "dev"
  component   = "networking"
  
  # Cost optimization settings for development
  cost_optimization = {
    enable_nat_gateway = false
    enable_s3_endpoint = true
    enable_dynamodb_endpoint = true
    enable_flow_logs = true
  }
  
  # Security settings for development
  security = {
    enable_flow_logs = true
    flow_log_destination_type = "cloud-watch-logs"
    enable_dns_hostnames = true
    enable_dns_support = true
  }
  
  # Network configuration for development
  network = {
    vpc_cidr = "10.0.0.0/16"
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
  }
}

# Terragrunt hooks
terraform {
  before_hook "before_hook" {
    commands     = ["apply", "plan"]
    execute      = ["echo", "Setting up networking for development environment"]
  }
  
  after_hook "after_hook" {
    commands     = ["apply"]
    execute      = ["echo", "Networking setup completed for development environment"]
  }
}

# Error handling
error_hook "error_hook" {
  commands  = ["apply", "plan", "destroy"]
  execute   = ["echo", "Error occurred during networking setup for development environment"]
  on_errors = [
    ".*",
  ]
}

# Skip conditions (if any)
skip = false

# Retry configuration
retryable_errors = [
  "ThrottlingException",
  "RequestLimitExceeded",
  "ServiceUnavailable",
  "InternalError"
]

# Retry settings
retry_max_attempts = 3
retry_sleep_interval_sec = 30
