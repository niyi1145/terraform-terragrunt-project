# Database Module - Main Configuration
# This module creates RDS instances, parameter groups, and database security

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

# Random password for database
resource "random_password" "db_password" {
  length  = 16
  special = true
}

# Store password in AWS Secrets Manager
resource "aws_secretsmanager_secret" "db_password" {
  name                    = "${var.environment}-${var.app_name}-db-password"
  description             = "Database password for ${var.environment}-${var.app_name}"
  recovery_window_in_days = var.secret_recovery_window_days
  kms_key_id              = var.kms_key_id

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.app_name}-db-password"
    Type = "Secrets Manager Secret"
  })
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id = aws_secretsmanager_secret.db_password.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_password.result
  })
}

# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.environment}-${var.app_name}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.app_name}-db-subnet-group"
    Type = "DB Subnet Group"
  })
}

# DB Parameter Group
resource "aws_db_parameter_group" "main" {
  family = var.db_parameter_group_family
  name   = "${var.environment}-${var.app_name}-db-params"

  dynamic "parameter" {
    for_each = var.db_parameters
    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.app_name}-db-params"
    Type = "DB Parameter Group"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# DB Option Group
resource "aws_db_option_group" "main" {
  count = var.create_option_group ? 1 : 0

  name                     = "${var.environment}-${var.app_name}-db-options"
  option_group_description = "Option group for ${var.environment}-${var.app_name}"
  engine_name              = var.engine
  major_engine_version     = var.major_engine_version

  dynamic "option" {
    for_each = var.db_options
    content {
      option_name = option.value.option_name

      dynamic "option_settings" {
        for_each = option.value.option_settings
        content {
          name  = option_settings.value.name
          value = option_settings.value.value
        }
      }
    }
  }

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.app_name}-db-options"
    Type = "DB Option Group"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# RDS Instance
resource "aws_db_instance" "main" {
  identifier = "${var.environment}-${var.app_name}-db"

  # Engine configuration
  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class

  # Storage configuration
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = var.storage_type
  storage_encrypted     = var.storage_encrypted
  kms_key_id           = var.kms_key_id

  # Database configuration
  db_name  = var.db_name
  username = var.db_username
  password = random_password.db_password.result

  # Network configuration
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = var.security_group_ids
  publicly_accessible    = var.publicly_accessible
  port                   = var.port

  # Parameter and option groups
  parameter_group_name = aws_db_parameter_group.main.name
  option_group_name    = var.create_option_group ? aws_db_option_group.main[0].name : null

  # Backup configuration
  backup_retention_period = var.backup_retention_period
  backup_window          = var.backup_window
  maintenance_window     = var.maintenance_window
  copy_tags_to_snapshot  = var.copy_tags_to_snapshot

  # Monitoring configuration
  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = var.monitoring_interval > 0 ? aws_iam_role.rds_enhanced_monitoring[0].arn : null

  # Performance Insights
  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_retention_period
  performance_insights_kms_key_id       = var.performance_insights_kms_key_id

  # Deletion protection
  deletion_protection = var.deletion_protection
  skip_final_snapshot = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.environment}-${var.app_name}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  # Multi-AZ configuration
  multi_az = var.multi_az

  # Read replicas
  replicate_source_db = var.replicate_source_db

  # Auto minor version upgrade
  auto_minor_version_upgrade = var.auto_minor_version_upgrade

  # Apply immediately
  apply_immediately = var.apply_immediately

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.app_name}-db"
    Type = "RDS Instance"
  })

  lifecycle {
    ignore_changes = [
      password,
      final_snapshot_identifier,
    ]
  }
}

# IAM Role for Enhanced Monitoring
resource "aws_iam_role" "rds_enhanced_monitoring" {
  count = var.monitoring_interval > 0 ? 1 : 0

  name = "${var.environment}-${var.app_name}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.app_name}-rds-monitoring-role"
    Type = "IAM Role"
  })
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  count = var.monitoring_interval > 0 ? 1 : 0

  role       = aws_iam_role.rds_enhanced_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "db_logs" {
  for_each = toset(var.enabled_cloudwatch_logs_exports)

  name              = "/aws/rds/instance/${aws_db_instance.main.identifier}/${each.key}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_id

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.app_name}-db-logs-${each.key}"
    Type = "CloudWatch Log Group"
  })
}

# DB Snapshot (if specified)
resource "aws_db_snapshot" "main" {
  count = var.create_snapshot ? 1 : 0

  db_instance_identifier = aws_db_instance.main.id
  db_snapshot_identifier = "${var.environment}-${var.app_name}-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.app_name}-db-snapshot"
    Type = "DB Snapshot"
  })
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.environment}-${var.app_name}-db-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = var.cpu_high_threshold
  alarm_description   = "This metric monitors RDS cpu utilization"
  alarm_actions       = var.alarm_actions

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.app_name}-db-cpu-high-alarm"
    Type = "CloudWatch Alarm"
  })
}

resource "aws_cloudwatch_metric_alarm" "freeable_memory_low" {
  alarm_name          = "${var.environment}-${var.app_name}-db-memory-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "FreeableMemory"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = var.memory_low_threshold
  alarm_description   = "This metric monitors RDS freeable memory"
  alarm_actions       = var.alarm_actions

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.app_name}-db-memory-low-alarm"
    Type = "CloudWatch Alarm"
  })
}

resource "aws_cloudwatch_metric_alarm" "free_storage_space_low" {
  alarm_name          = "${var.environment}-${var.app_name}-db-storage-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = var.storage_low_threshold
  alarm_description   = "This metric monitors RDS free storage space"
  alarm_actions       = var.alarm_actions

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.app_name}-db-storage-low-alarm"
    Type = "CloudWatch Alarm"
  })
}

# SNS Topic for database notifications
resource "aws_sns_topic" "db_notifications" {
  count = var.enable_sns_notifications ? 1 : 0

  name = "${var.environment}-${var.app_name}-db-notifications"
  kms_master_key_id = var.kms_key_id

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.app_name}-db-sns-topic"
    Type = "SNS Topic"
  })
}

# SNS Topic Subscription
resource "aws_sns_topic_subscription" "db_notifications" {
  count = var.enable_sns_notifications && var.sns_endpoint != "" ? 1 : 0

  topic_arn = aws_sns_topic.db_notifications[0].arn
  protocol  = var.sns_protocol
  endpoint  = var.sns_endpoint
}

# EventBridge Rule for database events
resource "aws_cloudwatch_event_rule" "db_events" {
  count = var.enable_eventbridge ? 1 : 0

  name        = "${var.environment}-${var.app_name}-db-events"
  description = "Capture RDS database events"

  event_pattern = jsonencode({
    source      = ["aws.rds"]
    detail-type = ["RDS DB Instance Event"]
    detail = {
      SourceIds = [aws_db_instance.main.id]
    }
  })

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.app_name}-db-events-rule"
    Type = "EventBridge Rule"
  })
}

resource "aws_cloudwatch_event_target" "db_events" {
  count = var.enable_eventbridge ? 1 : 0

  rule      = aws_cloudwatch_event_rule.db_events[0].name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.db_notifications[0].arn
}
