# Database Module - Variables
# This file defines all input variables for the database module

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "app_name" {
  description = "Application name"
  type        = string
  default     = "app"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

# Database Configuration
variable "engine" {
  description = "Database engine (mysql, postgres, mariadb, oracle-ee, sqlserver-ee, sqlserver-se, sqlserver-ex, sqlserver-web)"
  type        = string
  default     = "mysql"
  validation {
    condition = contains([
      "mysql", "postgres", "mariadb", "oracle-ee", 
      "sqlserver-ee", "sqlserver-se", "sqlserver-ex", "sqlserver-web"
    ], var.engine)
    error_message = "Engine must be one of the supported database engines."
  }
}

variable "engine_version" {
  description = "Database engine version"
  type        = string
  default     = ""
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Initial allocated storage in GB"
  type        = number
  default     = 20
  validation {
    condition     = var.allocated_storage >= 20
    error_message = "Allocated storage must be at least 20 GB."
  }
}

variable "max_allocated_storage" {
  description = "Maximum allocated storage in GB (for autoscaling)"
  type        = number
  default     = 100
}

variable "storage_type" {
  description = "Storage type (standard, gp2, gp3, io1, io2)"
  type        = string
  default     = "gp3"
  validation {
    condition     = contains(["standard", "gp2", "gp3", "io1", "io2"], var.storage_type)
    error_message = "Storage type must be one of: standard, gp2, gp3, io1, io2."
  }
}

variable "storage_encrypted" {
  description = "Enable storage encryption"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ID for encryption"
  type        = string
  default     = ""
}

# Database Settings
variable "db_name" {
  description = "Name of the database to create"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "admin"
}

variable "port" {
  description = "Database port"
  type        = number
  default     = 3306
}

# Network Configuration
variable "subnet_ids" {
  description = "List of subnet IDs for the DB subnet group"
  type        = list(string)
  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "At least 2 subnet IDs are required for high availability."
  }
}

variable "security_group_ids" {
  description = "List of security group IDs"
  type        = list(string)
}

variable "publicly_accessible" {
  description = "Make the database publicly accessible"
  type        = bool
  default     = false
}

# Parameter Group Configuration
variable "db_parameter_group_family" {
  description = "DB parameter group family"
  type        = string
  default     = "mysql8.0"
}

variable "db_parameters" {
  description = "List of DB parameters to apply"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

# Option Group Configuration
variable "create_option_group" {
  description = "Create DB option group"
  type        = bool
  default     = false
}

variable "major_engine_version" {
  description = "Major engine version for option group"
  type        = string
  default     = "8.0"
}

variable "db_options" {
  description = "List of DB options to apply"
  type = list(object({
    option_name = string
    option_settings = list(object({
      name  = string
      value = string
    }))
  }))
  default = []
}

# Backup Configuration
variable "backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
  validation {
    condition     = var.backup_retention_period >= 0 && var.backup_retention_period <= 35
    error_message = "Backup retention period must be between 0 and 35 days."
  }
}

variable "backup_window" {
  description = "Backup window (UTC)"
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "Maintenance window (UTC)"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "copy_tags_to_snapshot" {
  description = "Copy tags to snapshots"
  type        = bool
  default     = true
}

# Monitoring Configuration
variable "monitoring_interval" {
  description = "Enhanced monitoring interval in seconds (0, 1, 5, 10, 15, 30, 60)"
  type        = number
  default     = 0
  validation {
    condition     = contains([0, 1, 5, 10, 15, 30, 60], var.monitoring_interval)
    error_message = "Monitoring interval must be one of: 0, 1, 5, 10, 15, 30, 60."
  }
}

variable "performance_insights_enabled" {
  description = "Enable Performance Insights"
  type        = bool
  default     = false
}

variable "performance_insights_retention_period" {
  description = "Performance Insights retention period in days (7, 31, 62, 93, 124, 155, 186, 217, 248, 279, 310, 341, 372, 403, 434, 465, 496, 527, 558, 589, 620, 651, 682, 713, 744, 775, 806, 837, 868, 899, 930)"
  type        = number
  default     = 7
}

variable "performance_insights_kms_key_id" {
  description = "KMS key ID for Performance Insights"
  type        = string
  default     = ""
}

# CloudWatch Logs
variable "enabled_cloudwatch_logs_exports" {
  description = "List of log types to export to CloudWatch"
  type        = list(string)
  default     = []
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

# Deletion Protection
variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on deletion"
  type        = bool
  default     = false
}

# High Availability
variable "multi_az" {
  description = "Enable Multi-AZ deployment"
  type        = bool
  default     = false
}

# Read Replicas
variable "replicate_source_db" {
  description = "Source DB identifier for read replica"
  type        = string
  default     = ""
}

# Auto Minor Version Upgrade
variable "auto_minor_version_upgrade" {
  description = "Enable auto minor version upgrade"
  type        = bool
  default     = true
}

# Apply Changes
variable "apply_immediately" {
  description = "Apply changes immediately"
  type        = bool
  default     = false
}

# Secrets Manager
variable "secret_recovery_window_days" {
  description = "Secrets Manager recovery window in days"
  type        = number
  default     = 7
}

# CloudWatch Alarms
variable "cpu_high_threshold" {
  description = "CPU utilization high threshold"
  type        = number
  default     = 80
}

variable "memory_low_threshold" {
  description = "Freeable memory low threshold in bytes"
  type        = number
  default     = 1000000000  # 1GB
}

variable "storage_low_threshold" {
  description = "Free storage space low threshold in bytes"
  type        = number
  default     = 2000000000  # 2GB
}

variable "alarm_actions" {
  description = "List of ARNs to notify when alarm triggers"
  type        = list(string)
  default     = []
}

# SNS Notifications
variable "enable_sns_notifications" {
  description = "Enable SNS notifications"
  type        = bool
  default     = false
}

variable "sns_endpoint" {
  description = "SNS endpoint (email, SMS, etc.)"
  type        = string
  default     = ""
}

variable "sns_protocol" {
  description = "SNS protocol (email, sms, sqs, etc.)"
  type        = string
  default     = "email"
}

# EventBridge
variable "enable_eventbridge" {
  description = "Enable EventBridge for database events"
  type        = bool
  default     = false
}

# Snapshots
variable "create_snapshot" {
  description = "Create initial snapshot"
  type        = bool
  default     = false
}

# Common Tags
variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# Cost Optimization
variable "enable_cost_optimization" {
  description = "Enable cost optimization features"
  type        = bool
  default     = true
}

# Security
variable "enable_encryption" {
  description = "Enable encryption at rest"
  type        = bool
  default     = true
}

variable "enable_backup" {
  description = "Enable automated backups"
  type        = bool
  default     = true
}

variable "enable_monitoring" {
  description = "Enable monitoring and alerting"
  type        = bool
  default     = true
}
