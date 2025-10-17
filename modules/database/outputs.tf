# Database Module - Outputs
# This file defines all output values for the database module

# RDS Instance Outputs
output "db_instance_id" {
  description = "ID of the RDS instance"
  value       = aws_db_instance.main.id
}

output "db_instance_arn" {
  description = "ARN of the RDS instance"
  value       = aws_db_instance.main.arn
}

output "db_instance_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.main.endpoint
}

output "db_instance_hosted_zone_id" {
  description = "Hosted zone ID of the RDS instance"
  value       = aws_db_instance.main.hosted_zone_id
}

output "db_instance_address" {
  description = "RDS instance address"
  value       = aws_db_instance.main.address
}

output "db_instance_port" {
  description = "RDS instance port"
  value       = aws_db_instance.main.port
}

output "db_instance_name" {
  description = "Name of the RDS instance"
  value       = aws_db_instance.main.db_name
}

output "db_instance_username" {
  description = "Username of the RDS instance"
  value       = aws_db_instance.main.username
}

output "db_instance_engine" {
  description = "Engine of the RDS instance"
  value       = aws_db_instance.main.engine
}

output "db_instance_engine_version" {
  description = "Engine version of the RDS instance"
  value       = aws_db_instance.main.engine_version
}

output "db_instance_class" {
  description = "Instance class of the RDS instance"
  value       = aws_db_instance.main.instance_class
}

output "db_instance_allocated_storage" {
  description = "Allocated storage of the RDS instance"
  value       = aws_db_instance.main.allocated_storage
}

output "db_instance_storage_type" {
  description = "Storage type of the RDS instance"
  value       = aws_db_instance.main.storage_type
}

output "db_instance_storage_encrypted" {
  description = "Storage encryption status of the RDS instance"
  value       = aws_db_instance.main.storage_encrypted
}

output "db_instance_kms_key_id" {
  description = "KMS key ID of the RDS instance"
  value       = aws_db_instance.main.kms_key_id
}

output "db_instance_multi_az" {
  description = "Multi-AZ status of the RDS instance"
  value       = aws_db_instance.main.multi_az
}

output "db_instance_availability_zone" {
  description = "Availability zone of the RDS instance"
  value       = aws_db_instance.main.availability_zone
}

output "db_instance_backup_retention_period" {
  description = "Backup retention period of the RDS instance"
  value       = aws_db_instance.main.backup_retention_period
}

output "db_instance_backup_window" {
  description = "Backup window of the RDS instance"
  value       = aws_db_instance.main.backup_window
}

output "db_instance_maintenance_window" {
  description = "Maintenance window of the RDS instance"
  value       = aws_db_instance.main.maintenance_window
}

output "db_instance_monitoring_interval" {
  description = "Monitoring interval of the RDS instance"
  value       = aws_db_instance.main.monitoring_interval
}

output "db_instance_monitoring_role_arn" {
  description = "Monitoring role ARN of the RDS instance"
  value       = aws_db_instance.main.monitoring_role_arn
}

output "db_instance_performance_insights_enabled" {
  description = "Performance Insights status of the RDS instance"
  value       = aws_db_instance.main.performance_insights_enabled
}

output "db_instance_performance_insights_retention_period" {
  description = "Performance Insights retention period of the RDS instance"
  value       = aws_db_instance.main.performance_insights_retention_period
}

output "db_instance_performance_insights_kms_key_id" {
  description = "Performance Insights KMS key ID of the RDS instance"
  value       = aws_db_instance.main.performance_insights_kms_key_id
}

output "db_instance_deletion_protection" {
  description = "Deletion protection status of the RDS instance"
  value       = aws_db_instance.main.deletion_protection
}

output "db_instance_skip_final_snapshot" {
  description = "Skip final snapshot status of the RDS instance"
  value       = aws_db_instance.main.skip_final_snapshot
}

output "db_instance_final_snapshot_identifier" {
  description = "Final snapshot identifier of the RDS instance"
  value       = aws_db_instance.main.final_snapshot_identifier
}

output "db_instance_auto_minor_version_upgrade" {
  description = "Auto minor version upgrade status of the RDS instance"
  value       = aws_db_instance.main.auto_minor_version_upgrade
}

output "db_instance_apply_immediately" {
  description = "Apply immediately status of the RDS instance"
  value       = aws_db_instance.main.apply_immediately
}

output "db_instance_publicly_accessible" {
  description = "Publicly accessible status of the RDS instance"
  value       = aws_db_instance.main.publicly_accessible
}

output "db_instance_vpc_security_group_ids" {
  description = "VPC security group IDs of the RDS instance"
  value       = aws_db_instance.main.vpc_security_group_ids
}

output "db_instance_db_subnet_group_name" {
  description = "DB subnet group name of the RDS instance"
  value       = aws_db_instance.main.db_subnet_group_name
}

output "db_instance_parameter_group_name" {
  description = "Parameter group name of the RDS instance"
  value       = aws_db_instance.main.parameter_group_name
}

output "db_instance_option_group_name" {
  description = "Option group name of the RDS instance"
  value       = aws_db_instance.main.option_group_name
}

# DB Subnet Group Outputs
output "db_subnet_group_id" {
  description = "ID of the DB subnet group"
  value       = aws_db_subnet_group.main.id
}

output "db_subnet_group_arn" {
  description = "ARN of the DB subnet group"
  value       = aws_db_subnet_group.main.arn
}

output "db_subnet_group_name" {
  description = "Name of the DB subnet group"
  value       = aws_db_subnet_group.main.name
}

output "db_subnet_group_subnet_ids" {
  description = "Subnet IDs of the DB subnet group"
  value       = aws_db_subnet_group.main.subnet_ids
}

# DB Parameter Group Outputs
output "db_parameter_group_id" {
  description = "ID of the DB parameter group"
  value       = aws_db_parameter_group.main.id
}

output "db_parameter_group_arn" {
  description = "ARN of the DB parameter group"
  value       = aws_db_parameter_group.main.arn
}

output "db_parameter_group_name" {
  description = "Name of the DB parameter group"
  value       = aws_db_parameter_group.main.name
}

output "db_parameter_group_family" {
  description = "Family of the DB parameter group"
  value       = aws_db_parameter_group.main.family
}

# DB Option Group Outputs
output "db_option_group_id" {
  description = "ID of the DB option group"
  value       = var.create_option_group ? aws_db_option_group.main[0].id : null
}

output "db_option_group_arn" {
  description = "ARN of the DB option group"
  value       = var.create_option_group ? aws_db_option_group.main[0].arn : null
}

output "db_option_group_name" {
  description = "Name of the DB option group"
  value       = var.create_option_group ? aws_db_option_group.main[0].name : null
}

# Secrets Manager Outputs
output "db_password_secret_id" {
  description = "ID of the database password secret"
  value       = aws_secretsmanager_secret.db_password.id
}

output "db_password_secret_arn" {
  description = "ARN of the database password secret"
  value       = aws_secretsmanager_secret.db_password.arn
}

output "db_password_secret_name" {
  description = "Name of the database password secret"
  value       = aws_secretsmanager_secret.db_password.name
}

# IAM Role Outputs
output "rds_monitoring_role_id" {
  description = "ID of the RDS monitoring role"
  value       = var.monitoring_interval > 0 ? aws_iam_role.rds_enhanced_monitoring[0].id : null
}

output "rds_monitoring_role_arn" {
  description = "ARN of the RDS monitoring role"
  value       = var.monitoring_interval > 0 ? aws_iam_role.rds_enhanced_monitoring[0].arn : null
}

output "rds_monitoring_role_name" {
  description = "Name of the RDS monitoring role"
  value       = var.monitoring_interval > 0 ? aws_iam_role.rds_enhanced_monitoring[0].name : null
}

# CloudWatch Log Group Outputs
output "db_log_groups" {
  description = "CloudWatch log groups for the database"
  value = {
    for k, v in aws_cloudwatch_log_group.db_logs : k => {
      id   = v.id
      arn  = v.arn
      name = v.name
    }
  }
}

# CloudWatch Alarm Outputs
output "db_alarms" {
  description = "CloudWatch alarms for the database"
  value = {
    cpu_high = {
      id   = aws_cloudwatch_metric_alarm.cpu_high.id
      arn  = aws_cloudwatch_metric_alarm.cpu_high.arn
      name = aws_cloudwatch_metric_alarm.cpu_high.alarm_name
    }
    memory_low = {
      id   = aws_cloudwatch_metric_alarm.freeable_memory_low.id
      arn  = aws_cloudwatch_metric_alarm.freeable_memory_low.arn
      name = aws_cloudwatch_metric_alarm.freeable_memory_low.alarm_name
    }
    storage_low = {
      id   = aws_cloudwatch_metric_alarm.free_storage_space_low.id
      arn  = aws_cloudwatch_metric_alarm.free_storage_space_low.arn
      name = aws_cloudwatch_metric_alarm.free_storage_space_low.alarm_name
    }
  }
}

# SNS Topic Outputs
output "db_sns_topic_id" {
  description = "ID of the database SNS topic"
  value       = var.enable_sns_notifications ? aws_sns_topic.db_notifications[0].id : null
}

output "db_sns_topic_arn" {
  description = "ARN of the database SNS topic"
  value       = var.enable_sns_notifications ? aws_sns_topic.db_notifications[0].arn : null
}

output "db_sns_topic_name" {
  description = "Name of the database SNS topic"
  value       = var.enable_sns_notifications ? aws_sns_topic.db_notifications[0].name : null
}

# EventBridge Outputs
output "db_eventbridge_rule_id" {
  description = "ID of the database EventBridge rule"
  value       = var.enable_eventbridge ? aws_cloudwatch_event_rule.db_events[0].id : null
}

output "db_eventbridge_rule_arn" {
  description = "ARN of the database EventBridge rule"
  value       = var.enable_eventbridge ? aws_cloudwatch_event_rule.db_events[0].arn : null
}

output "db_eventbridge_rule_name" {
  description = "Name of the database EventBridge rule"
  value       = var.enable_eventbridge ? aws_cloudwatch_event_rule.db_events[0].name : null
}

# DB Snapshot Outputs
output "db_snapshot_id" {
  description = "ID of the database snapshot"
  value       = var.create_snapshot ? aws_db_snapshot.main[0].id : null
}

output "db_snapshot_arn" {
  description = "ARN of the database snapshot"
  value       = var.create_snapshot ? aws_db_snapshot.main[0].arn : null
}

output "db_snapshot_identifier" {
  description = "Identifier of the database snapshot"
  value       = var.create_snapshot ? aws_db_snapshot.main[0].db_snapshot_identifier : null
}

# Connection Information
output "db_connection_info" {
  description = "Database connection information"
  value = {
    endpoint = aws_db_instance.main.endpoint
    port     = aws_db_instance.main.port
    database = aws_db_instance.main.db_name
    username = aws_db_instance.main.username
    password_secret_arn = aws_secretsmanager_secret.db_password.arn
  }
  sensitive = true
}

# Summary Outputs
output "db_summary" {
  description = "Summary of the database configuration"
  value = {
    instance_id     = aws_db_instance.main.id
    engine          = aws_db_instance.main.engine
    engine_version  = aws_db_instance.main.engine_version
    instance_class  = aws_db_instance.main.instance_class
    allocated_storage = aws_db_instance.main.allocated_storage
    multi_az        = aws_db_instance.main.multi_az
    backup_retention = aws_db_instance.main.backup_retention_period
    monitoring_interval = aws_db_instance.main.monitoring_interval
    performance_insights = aws_db_instance.main.performance_insights_enabled
    deletion_protection = aws_db_instance.main.deletion_protection
    publicly_accessible = aws_db_instance.main.publicly_accessible
  }
}

# Cost Estimation Outputs
output "estimated_monthly_cost" {
  description = "Estimated monthly cost for database resources"
  value = {
    db_instance_cost = var.instance_class == "db.t3.micro" ? 12.41 : 
                      var.instance_class == "db.t3.small" ? 24.82 :
                      var.instance_class == "db.t3.medium" ? 49.64 :
                      var.instance_class == "db.t3.large" ? 99.28 : 0
    storage_cost = var.allocated_storage * 0.115  # gp3 storage cost per GB
    backup_cost = var.backup_retention_period * var.allocated_storage * 0.095  # backup cost per GB
    monitoring_cost = var.monitoring_interval > 0 ? 1.50 : 0  # enhanced monitoring cost
    performance_insights_cost = var.performance_insights_enabled ? 0.60 : 0  # performance insights cost
    total_estimated_cost = (var.instance_class == "db.t3.micro" ? 12.41 : 
                           var.instance_class == "db.t3.small" ? 24.82 :
                           var.instance_class == "db.t3.medium" ? 49.64 :
                           var.instance_class == "db.t3.large" ? 99.28 : 0) +
                          (var.allocated_storage * 0.115) +
                          (var.backup_retention_period * var.allocated_storage * 0.095) +
                          (var.monitoring_interval > 0 ? 1.50 : 0) +
                          (var.performance_insights_enabled ? 0.60 : 0)
  }
}
