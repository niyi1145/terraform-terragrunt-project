# Development Environment - Compute Configuration
# This file configures the compute module for the development environment

# Include the root terragrunt.hcl configuration
include "root" {
  path = find_in_parent_folders()
}

# Include the compute module
terraform {
  source = "../../../modules/compute"
}

# Dependencies
dependency "networking" {
  config_path = "../networking"
  
  mock_outputs = {
    vpc_id                = "vpc-mock"
    private_subnet_ids    = ["subnet-mock-1", "subnet-mock-2"]
    public_subnet_ids     = ["subnet-mock-3", "subnet-mock-4"]
    security_group_ids    = {
      web_sg_id      = "sg-mock-web"
      app_sg_id      = "sg-mock-app"
      database_sg_id = "sg-mock-db"
    }
  }
  
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

# Environment-specific inputs
inputs = {
  # Environment
  environment = "dev"
  app_name    = "web"
  
  # Instance Configuration (cost-optimized for development)
  instance_type = "t3.micro"
  ami_id        = ""  # Use latest Amazon Linux 2
  
  # Auto Scaling Configuration (minimal for development)
  min_size         = 1
  max_size         = 2
  desired_capacity = 1
  
  # Load Balancer Configuration
  enable_load_balancer = true
  internal_load_balancer = false
  
  # Health Check Configuration
  health_check_type = "ELB"
  health_check_grace_period = 300
  
  # Auto Scaling Policies (conservative for development)
  scale_up_adjustment   = 1
  scale_down_adjustment = -1
  scale_up_cooldown     = 300
  scale_down_cooldown   = 300
  
  # CloudWatch Alarms (relaxed thresholds for development)
  cpu_high_threshold = 80
  cpu_low_threshold  = 20
  
  # Load Balancer Configuration
  target_group_port     = 80
  target_group_protocol = "HTTP"
  listener_port         = 80
  listener_protocol     = "HTTP"
  
  # Health Check Configuration
  health_check_healthy_threshold   = 2
  health_check_unhealthy_threshold = 2
  health_check_timeout             = 5
  health_check_interval            = 30
  health_check_path                = "/"
  health_check_matcher             = "200"
  
  # Storage Configuration
  volume_size = 20
  volume_type = "gp3"
  
  # Security Configuration
  key_name = "dev-keypair"  # You'll need to create this key pair
  
  # Monitoring Configuration
  enable_detailed_monitoring = false  # Cost optimization
  enable_cloudwatch_logs     = true
  enable_cloudwatch_agent    = true
  log_retention_days         = 7  # Shorter retention for cost savings
  
  # SNS Configuration
  enable_sns_notifications = false  # Disable for development
  
  # SSL Configuration (disabled for development)
  ssl_certificate_arn = ""
  ssl_policy          = "ELBSecurityPolicy-TLS-1-2-2017-01"
  
  # Access Logs (disabled for development)
  enable_alb_access_logs = false
  alb_access_logs_bucket = ""
  alb_access_logs_prefix = ""
  
  # Deletion Protection (disabled for development)
  enable_deletion_protection = false
  
  # Network Configuration (from dependency)
  vpc_id                = dependency.networking.outputs.vpc_id
  subnet_ids            = dependency.networking.outputs.private_subnet_ids
  security_group_ids    = [dependency.networking.outputs.security_group_ids.app_sg_id]
  alb_subnet_ids        = dependency.networking.outputs.public_subnet_ids
  alb_security_group_ids = [dependency.networking.outputs.security_group_ids.web_sg_id]
  
  # Common tags
  common_tags = {
    Environment = "dev"
    CostCenter  = "development"
    Project     = "terraform-terragrunt-infrastructure"
    Owner       = "devops-team"
    ManagedBy   = "terragrunt"
    CreatedBy   = "terraform"
    Component   = "compute"
  }
}

# Generate backend configuration
remote_state {
  backend = "s3"
  config = {
    bucket         = "terraform-terragrunt-state-${get_aws_account_id()}"
    key            = "dev/compute/terraform.tfstate"
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
      Component   = "compute"
    }
  }
}
EOF
}

# Local values
locals {
  environment = "dev"
  component   = "compute"
  
  # Cost optimization settings for development
  cost_optimization = {
    instance_type = "t3.micro"
    min_size = 1
    max_size = 2
    desired_capacity = 1
    enable_detailed_monitoring = false
    log_retention_days = 7
    enable_sns_notifications = false
    enable_alb_access_logs = false
    enable_deletion_protection = false
  }
  
  # Security settings for development
  security = {
    key_name = "dev-keypair"
    volume_type = "gp3"
    volume_size = 20
  }
  
  # Monitoring settings for development
  monitoring = {
    enable_cloudwatch_logs = true
    enable_cloudwatch_agent = true
    cpu_high_threshold = 80
    cpu_low_threshold = 20
  }
}

# Terragrunt hooks
terraform {
  before_hook "before_hook" {
    commands     = ["apply", "plan"]
    execute      = ["echo", "Setting up compute resources for development environment"]
  }
  
  after_hook "after_hook" {
    commands     = ["apply"]
    execute      = ["echo", "Compute setup completed for development environment"]
  }
}

# Error handling
error_hook "error_hook" {
  commands  = ["apply", "plan", "destroy"]
  execute   = ["echo", "Error occurred during compute setup for development environment"]
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
  "InternalError",
  "InsufficientInstanceCapacity"
]

# Retry settings
retry_max_attempts = 3
retry_sleep_interval_sec = 30
