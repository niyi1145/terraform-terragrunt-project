# Monitoring Module - Main Configuration
# This module creates CloudWatch dashboards, alarms, and monitoring infrastructure

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.environment}-${var.app_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "InstanceId", var.instance_id],
            [".", "NetworkIn", ".", "."],
            [".", "NetworkOut", ".", "."],
            [".", "DiskReadOps", ".", "."],
            [".", "DiskWriteOps", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          title   = "EC2 Metrics"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.alb_arn_suffix],
            [".", "TargetResponseTime", ".", "."],
            [".", "HTTPCode_Target_2XX_Count", ".", "."],
            [".", "HTTPCode_Target_4XX_Count", ".", "."],
            [".", "HTTPCode_Target_5XX_Count", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          title   = "Application Load Balancer Metrics"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", var.db_instance_id],
            [".", "FreeableMemory", ".", "."],
            [".", "FreeStorageSpace", ".", "."],
            [".", "DatabaseConnections", ".", "."],
            [".", "ReadLatency", ".", "."],
            [".", "WriteLatency", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          title   = "RDS Metrics"
          period  = 300
        }
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.app_name}-dashboard"
    Type = "CloudWatch Dashboard"
  })
}

# SNS Topic for notifications
resource "aws_sns_topic" "alerts" {
  name = "${var.environment}-${var.app_name}-alerts"
  kms_master_key_id = var.kms_key_id

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.app_name}-alerts-topic"
    Type = "SNS Topic"
  })
}

# SNS Topic Subscription
resource "aws_sns_topic_subscription" "alerts" {
  count = var.sns_endpoint != "" ? 1 : 0

  topic_arn = aws_sns_topic.alerts.arn
  protocol  = var.sns_protocol
  endpoint  = var.sns_endpoint
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "application" {
  name              = "/aws/ec2/${var.environment}-${var.app_name}/application"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_id

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.app_name}-application-logs"
    Type = "CloudWatch Log Group"
  })
}

resource "aws_cloudwatch_log_group" "system" {
  name              = "/aws/ec2/${var.environment}-${var.app_name}/system"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_id

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.app_name}-system-logs"
    Type = "CloudWatch Log Group"
  })
}

resource "aws_cloudwatch_log_group" "database" {
  count = var.db_instance_id != "" ? 1 : 0

  name              = "/aws/rds/instance/${var.environment}-${var.app_name}/database"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_id

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.app_name}-database-logs"
    Type = "CloudWatch Log Group"
  })
}

# CloudWatch Alarms - EC2
resource "aws_cloudwatch_metric_alarm" "ec2_cpu_high" {
  count = var.instance_id != "" ? 1 : 0

  alarm_name          = "${var.environment}-${var.app_name}-ec2-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = var.ec2_cpu_high_threshold
  alarm_description   = "This metric monitors EC2 cpu utilization"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = var.instance_id
  }

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.app_name}-ec2-cpu-high-alarm"
    Type = "CloudWatch Alarm"
  })
}

resource "aws_cloudwatch_metric_alarm" "ec2_cpu_low" {
  count = var.instance_id != "" ? 1 : 0

  alarm_name          = "${var.environment}-${var.app_name}-ec2-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = var.ec2_cpu_low_threshold
  alarm_description   = "This metric monitors EC2 cpu utilization"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = var.instance_id
  }

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.app_name}-ec2-cpu-low-alarm"
    Type = "CloudWatch Alarm"
  })
}

resource "aws_cloudwatch_metric_alarm" "ec2_status_check_failed" {
  count = var.instance_id != "" ? 1 : 0

  alarm_name          = "${var.environment}-${var.app_name}-ec2-status-check-failed"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Maximum"
  threshold           = "0"
  alarm_description   = "This metric monitors EC2 status check"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    InstanceId = var.instance_id
  }

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.app_name}-ec2-status-check-failed-alarm"
    Type = "CloudWatch Alarm"
  })
}

# CloudWatch Alarms - Application Load Balancer
resource "aws_cloudwatch_metric_alarm" "alb_response_time_high" {
  count = var.alb_arn_suffix != "" ? 1 : 0

  alarm_name          = "${var.environment}-${var.app_name}-alb-response-time-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Average"
  threshold           = var.alb_response_time_threshold
  alarm_description   = "This metric monitors ALB response time"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.app_name}-alb-response-time-high-alarm"
    Type = "CloudWatch Alarm"
  })
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx_errors" {
  count = var.alb_arn_suffix != "" ? 1 : 0

  alarm_name          = "${var.environment}-${var.app_name}-alb-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Sum"
  threshold           = var.alb_5xx_error_threshold
  alarm_description   = "This metric monitors ALB 5XX errors"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.app_name}-alb-5xx-errors-alarm"
    Type = "CloudWatch Alarm"
  })
}

resource "aws_cloudwatch_metric_alarm" "alb_healthy_hosts_low" {
  count = var.alb_arn_suffix != "" ? 1 : 0

  alarm_name          = "${var.environment}-${var.app_name}-alb-healthy-hosts-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Average"
  threshold           = var.alb_healthy_hosts_threshold
  alarm_description   = "This metric monitors ALB healthy hosts"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.app_name}-alb-healthy-hosts-low-alarm"
    Type = "CloudWatch Alarm"
  })
}

# CloudWatch Alarms - RDS
resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  count = var.db_instance_id != "" ? 1 : 0

  alarm_name          = "${var.environment}-${var.app_name}-rds-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = var.rds_cpu_high_threshold
  alarm_description   = "This metric monitors RDS cpu utilization"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBInstanceIdentifier = var.db_instance_id
  }

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.app_name}-rds-cpu-high-alarm"
    Type = "CloudWatch Alarm"
  })
}

resource "aws_cloudwatch_metric_alarm" "rds_freeable_memory_low" {
  count = var.db_instance_id != "" ? 1 : 0

  alarm_name          = "${var.environment}-${var.app_name}-rds-memory-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "FreeableMemory"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = var.rds_memory_low_threshold
  alarm_description   = "This metric monitors RDS freeable memory"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBInstanceIdentifier = var.db_instance_id
  }

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.app_name}-rds-memory-low-alarm"
    Type = "CloudWatch Alarm"
  })
}

resource "aws_cloudwatch_metric_alarm" "rds_free_storage_space_low" {
  count = var.db_instance_id != "" ? 1 : 0

  alarm_name          = "${var.environment}-${var.app_name}-rds-storage-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = var.rds_storage_low_threshold
  alarm_description   = "This metric monitors RDS free storage space"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBInstanceIdentifier = var.db_instance_id
  }

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.app_name}-rds-storage-low-alarm"
    Type = "CloudWatch Alarm"
  })
}

# CloudWatch Alarms - Custom Metrics
resource "aws_cloudwatch_metric_alarm" "custom_metric_high" {
  count = var.custom_metric_name != "" ? 1 : 0

  alarm_name          = "${var.environment}-${var.app_name}-custom-metric-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = var.custom_metric_name
  namespace           = var.custom_metric_namespace
  period              = "300"
  statistic           = "Average"
  threshold           = var.custom_metric_threshold
  alarm_description   = "This metric monitors custom application metric"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = var.custom_metric_dimensions

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.app_name}-custom-metric-high-alarm"
    Type = "CloudWatch Alarm"
  })
}

# CloudWatch Log Metric Filters
resource "aws_cloudwatch_log_metric_filter" "error_logs" {
  name           = "${var.environment}-${var.app_name}-error-logs"
  log_group_name = aws_cloudwatch_log_group.application.name
  pattern        = "[timestamp, request_id, level=\"ERROR\", ...]"

  metric_transformation {
    name      = "ErrorCount"
    namespace = "Custom/Application"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "warning_logs" {
  name           = "${var.environment}-${var.app_name}-warning-logs"
  log_group_name = aws_cloudwatch_log_group.application.name
  pattern        = "[timestamp, request_id, level=\"WARN\", ...]"

  metric_transformation {
    name      = "WarningCount"
    namespace = "Custom/Application"
    value     = "1"
  }
}

# CloudWatch Alarms for Log Metrics
resource "aws_cloudwatch_metric_alarm" "error_logs_high" {
  alarm_name          = "${var.environment}-${var.app_name}-error-logs-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "ErrorCount"
  namespace           = "Custom/Application"
  period              = "300"
  statistic           = "Sum"
  threshold           = var.error_log_threshold
  alarm_description   = "This metric monitors application error logs"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.app_name}-error-logs-high-alarm"
    Type = "CloudWatch Alarm"
  })
}

# CloudWatch Insights Queries
resource "aws_cloudwatch_query_definition" "error_analysis" {
  name = "${var.environment}-${var.app_name}-error-analysis"

  log_group_names = [
    aws_cloudwatch_log_group.application.name
  ]

  query_string = <<EOF
fields @timestamp, @message
| filter @message like /ERROR/
| sort @timestamp desc
| limit 100
EOF
}

resource "aws_cloudwatch_query_definition" "performance_analysis" {
  name = "${var.environment}-${var.app_name}-performance-analysis"

  log_group_names = [
    aws_cloudwatch_log_group.application.name
  ]

  query_string = <<EOF
fields @timestamp, @message
| filter @message like /response_time/
| sort @timestamp desc
| limit 100
EOF
}

# EventBridge Rule for monitoring events
resource "aws_cloudwatch_event_rule" "monitoring_events" {
  name        = "${var.environment}-${var.app_name}-monitoring-events"
  description = "Capture monitoring events"

  event_pattern = jsonencode({
    source      = ["aws.cloudwatch"]
    detail-type = ["CloudWatch Alarm State Change"]
    detail = {
      state = {
        value = ["ALARM"]
      }
    }
  })

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.app_name}-monitoring-events-rule"
    Type = "EventBridge Rule"
  })
}

resource "aws_cloudwatch_event_target" "monitoring_events" {
  rule      = aws_cloudwatch_event_rule.monitoring_events.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.alerts.arn
}

# CloudWatch Synthetics Canary (optional)
resource "aws_synthetics_canary" "main" {
  count = var.enable_synthetics ? 1 : 0

  name                 = "${var.environment}-${var.app_name}-canary"
  artifact_s3_location = "s3://${var.synthetics_bucket}/canary/"
  execution_role_arn   = aws_iam_role.synthetics[0].arn
  handler              = "pageLoadBlueprint.handler"
  zip_file             = "synthetics_canary.zip"
  runtime_version      = "syn-nodejs-puppeteer-3.3"

  schedule {
    expression = "rate(5 minutes)"
  }

  run_config {
    active_tracing = false
  }

  success_retention_period = 30
  failure_retention_period = 30

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.app_name}-canary"
    Type = "Synthetics Canary"
  })
}

# IAM Role for Synthetics
resource "aws_iam_role" "synthetics" {
  count = var.enable_synthetics ? 1 : 0

  name = "${var.environment}-${var.app_name}-synthetics-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.app_name}-synthetics-role"
    Type = "IAM Role"
  })
}

resource "aws_iam_role_policy_attachment" "synthetics" {
  count = var.enable_synthetics ? 1 : 0

  role       = aws_iam_role.synthetics[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSSyntheticsRole"
}
