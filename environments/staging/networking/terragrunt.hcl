# Staging Environment - Networking Configuration
# This file configures the networking module for the staging environment

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
  environment = "staging"
  
  # VPC Configuration
  vpc_cidr = "10.1.0.0/16"
  
  # Subnet Configuration (production-like for staging)
  public_subnet_cidrs = [
    "10.1.1.0/24",
    "10.1.2.0/24",
    "10.1.3.0/24"
  ]
  
  private_subnet_cidrs = [
    "10.1.10.0/24",
    "10.1.20.0/24",
    "10.1.30.0/24"
  ]
  
  database_subnet_cidrs = [
    "10.1.40.0/24",
    "10.1.50.0/24",
    "10.1.60.0/24"
  ]
  
  # High availability for staging
  enable_nat_gateway = true
  enable_s3_endpoint = true
  enable_dynamodb_endpoint = true
  
  # Security settings
  enable_flow_logs = true
  flow_log_destination_type = "cloud-watch-logs"
  
  # Common tags
  common_tags = {
    Environment = "staging"
    CostCenter  = "staging"
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
    key            = "staging/networking/terraform.tfstate"
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
      Environment = "staging"
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
  environment = "staging"
  component   = "networking"
  
  # High availability settings for staging
  high_availability = {
    enable_nat_gateway = true
    enable_s3_endpoint = true
    enable_dynamodb_endpoint = true
    enable_flow_logs = true
  }
  
  # Security settings for staging
  security = {
    enable_flow_logs = true
    flow_log_destination_type = "cloud-watch-logs"
    enable_dns_hostnames = true
    enable_dns_support = true
  }
  
  # Network configuration for staging
  network = {
    vpc_cidr = "10.1.0.0/16"
    public_subnet_cidrs = [
      "10.1.1.0/24",
      "10.1.2.0/24",
      "10.1.3.0/24"
    ]
    private_subnet_cidrs = [
      "10.1.10.0/24",
      "10.1.20.0/24",
      "10.1.30.0/24"
    ]
    database_subnet_cidrs = [
      "10.1.40.0/24",
      "10.1.50.0/24",
      "10.1.60.0/24"
    ]
  }
}

# Terragrunt hooks
terraform {
  before_hook "before_hook" {
    commands     = ["apply", "plan"]
    execute      = ["echo", "Setting up networking for staging environment"]
  }
  
  after_hook "after_hook" {
    commands     = ["apply"]
    execute      = ["echo", "Networking setup completed for staging environment"]
  }
}

# Error handling
error_hook "error_hook" {
  commands  = ["apply", "plan", "destroy"]
  execute   = ["echo", "Error occurred during networking setup for staging environment"]
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
