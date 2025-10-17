# Production Environment - Networking Configuration
# This file configures the networking module for the production environment

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
  environment = "prod"
  
  # VPC Configuration
  vpc_cidr = "10.2.0.0/16"
  
  # Subnet Configuration (high availability for production)
  public_subnet_cidrs = [
    "10.2.1.0/24",
    "10.2.2.0/24",
    "10.2.3.0/24",
    "10.2.4.0/24"
  ]
  
  private_subnet_cidrs = [
    "10.2.10.0/24",
    "10.2.20.0/24",
    "10.2.30.0/24",
    "10.2.40.0/24"
  ]
  
  database_subnet_cidrs = [
    "10.2.50.0/24",
    "10.2.60.0/24",
    "10.2.70.0/24",
    "10.2.80.0/24"
  ]
  
  # Full high availability for production
  enable_nat_gateway = true
  enable_s3_endpoint = true
  enable_dynamodb_endpoint = true
  
  # Enhanced security for production
  enable_flow_logs = true
  flow_log_destination_type = "cloud-watch-logs"
  
  # Common tags
  common_tags = {
    Environment = "prod"
    CostCenter  = "production"
    Project     = "terraform-terragrunt-infrastructure"
    Owner       = "devops-team"
    ManagedBy   = "terragrunt"
    CreatedBy   = "terraform"
    Criticality = "high"
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
    key            = "prod/networking/terraform.tfstate"
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
      Environment = "prod"
      Project     = "terraform-terragrunt-infrastructure"
      ManagedBy   = "terragrunt"
      Owner       = "devops-team"
      CreatedBy   = "terraform"
      Criticality = "high"
    }
  }
}
EOF
}

# Local values
locals {
  environment = "prod"
  component   = "networking"
  
  # Full high availability settings for production
  high_availability = {
    enable_nat_gateway = true
    enable_s3_endpoint = true
    enable_dynamodb_endpoint = true
    enable_flow_logs = true
  }
  
  # Enhanced security settings for production
  security = {
    enable_flow_logs = true
    flow_log_destination_type = "cloud-watch-logs"
    enable_dns_hostnames = true
    enable_dns_support = true
  }
  
  # Network configuration for production
  network = {
    vpc_cidr = "10.2.0.0/16"
    public_subnet_cidrs = [
      "10.2.1.0/24",
      "10.2.2.0/24",
      "10.2.3.0/24",
      "10.2.4.0/24"
    ]
    private_subnet_cidrs = [
      "10.2.10.0/24",
      "10.2.20.0/24",
      "10.2.30.0/24",
      "10.2.40.0/24"
    ]
    database_subnet_cidrs = [
      "10.2.50.0/24",
      "10.2.60.0/24",
      "10.2.70.0/24",
      "10.2.80.0/24"
    ]
  }
}

# Terragrunt hooks
terraform {
  before_hook "before_hook" {
    commands     = ["apply", "plan"]
    execute      = ["echo", "Setting up networking for production environment"]
  }
  
  after_hook "after_hook" {
    commands     = ["apply"]
    execute      = ["echo", "Networking setup completed for production environment"]
  }
}

# Error handling
error_hook "error_hook" {
  commands  = ["apply", "plan", "destroy"]
  execute   = ["echo", "Error occurred during networking setup for production environment"]
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
retry_max_attempts = 5
retry_sleep_interval_sec = 60
