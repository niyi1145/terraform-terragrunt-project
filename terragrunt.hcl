# Root Terragrunt Configuration
# This file defines global settings and remote state configuration

# Configure Terragrunt to automatically store tfstate files in an S3 bucket
remote_state {
  backend = "s3"
  config = {
    bucket         = "terraform-terragrunt-state-${get_aws_account_id()}"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-terragrunt-locks"
    
    s3_bucket_tags = {
      Owner       = "DevOps Team"
      Environment = "Global"
      Project     = "Terraform-Terragrunt-Infrastructure"
      ManagedBy   = "Terragrunt"
    }
    
    dynamodb_table_tags = {
      Owner       = "DevOps Team"
      Environment = "Global"
      Project     = "Terraform-Terragrunt-Infrastructure"
      ManagedBy   = "Terragrunt"
    }
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
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "Terraform-Terragrunt-Infrastructure"
      ManagedBy   = "Terragrunt"
      Environment = var.environment
      Owner       = "DevOps Team"
      CreatedBy   = "Terraform"
    }
  }
}
EOF
}

# Configure input variables that will be available to all child modules
inputs = {
  # Common variables across all environments
  aws_region = "us-east-1"
  
  # Environment-specific variables will be overridden in child terragrunt.hcl files
  environment = "default"
  
  # Common tags
  common_tags = {
    Project     = "Terraform-Terragrunt-Infrastructure"
    ManagedBy   = "Terragrunt"
    Owner       = "DevOps Team"
    CreatedBy   = "Terraform"
  }
  
  # Cost optimization settings
  enable_cost_optimization = true
  enable_monitoring       = true
  enable_backup          = true
  
  # Security settings
  enable_encryption      = true
  enable_logging         = true
  enable_audit_trail     = true
}

# Configure how Terragrunt handles dependencies
dependency "networking" {
  config_path = "../networking"
  
  mock_outputs = {
    vpc_id                = "vpc-mock"
    private_subnet_ids    = ["subnet-mock-1", "subnet-mock-2"]
    public_subnet_ids     = ["subnet-mock-3", "subnet-mock-4"]
    database_subnet_ids   = ["subnet-mock-5", "subnet-mock-6"]
    internet_gateway_id   = "igw-mock"
    nat_gateway_ids       = ["nat-mock-1", "nat-mock-2"]
    security_group_ids    = {
      web_sg_id      = "sg-mock-web"
      app_sg_id      = "sg-mock-app"
      database_sg_id = "sg-mock-db"
    }
  }
  
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

# Configure Terragrunt to run commands in parallel when possible
terraform {
  extra_arguments "parallelism" {
    commands = get_terraform_commands_that_need_parallelism()
    arguments = ["-parallelism=10"]
  }
  
  extra_arguments "var_files" {
    commands = get_terraform_commands_that_need_vars()
    arguments = ["-var-file=terraform.tfvars"]
  }
  
  before_hook "before_hook" {
    commands     = ["apply", "plan"]
    execute      = ["echo", "Running Terraform ${get_terraform_command()} for ${local.environment}-${local.component}"]
  }
  
  after_hook "after_hook" {
    commands     = ["apply"]
    execute      = ["echo", "Terraform ${get_terraform_command()} completed for ${local.environment}-${local.component}"]
  }
}

# Helper functions
locals {
  # Get the current AWS account ID
  aws_account_id = get_aws_account_id()
  
  # Get the current AWS region
  aws_region = "us-east-1"
  
  # Get the current environment from the directory structure
  environment = basename(get_parent_terragrunt_dir())
  
  # Get the current component from the directory structure
  component = basename(get_terragrunt_dir())
  
  # Generate a unique name for resources
  resource_name = "${local.environment}-${local.component}"
  
  # Common tags for all resources
  common_tags = {
    Project     = "Terraform-Terragrunt-Infrastructure"
    ManagedBy   = "Terragrunt"
    Environment = local.environment
    Component   = local.component
    Owner       = "DevOps Team"
    CreatedBy   = "Terraform"
  }
}

# Configure Terragrunt to skip certain operations in certain environments
skip = false

# Configure Terragrunt to handle errors gracefully
error_hook "error_hook" {
  commands  = ["apply", "plan", "destroy"]
  execute   = ["echo", "Error occurred during Terraform ${get_terraform_command()} for ${local.environment}-${local.component}"]
  on_errors = [
    ".*",
  ]
}
