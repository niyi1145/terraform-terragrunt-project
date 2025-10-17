# Compute Module - Main Configuration
# This module creates EC2 instances, Auto Scaling Groups, and Load Balancers

# Data sources
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

# Launch Template
resource "aws_launch_template" "main" {
  name_prefix   = "${var.environment}-"
  image_id      = var.ami_id != "" ? var.ami_id : data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  key_name      = var.key_name

  vpc_security_group_ids = var.security_group_ids

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    environment = var.environment
    app_name    = var.app_name
  }))

  iam_instance_profile {
    name = aws_iam_instance_profile.main.name
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = var.volume_size
      volume_type           = var.volume_type
      delete_on_termination = true
      encrypted             = true
      kms_key_id            = var.kms_key_id
    }
  }

  monitoring {
    enabled = var.enable_detailed_monitoring
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.common_tags, {
      Name = "${var.environment}-${var.app_name}-instance"
      Type = "EC2 Instance"
    })
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(var.common_tags, {
      Name = "${var.environment}-${var.app_name}-volume"
      Type = "EBS Volume"
    })
  }

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.app_name}-launch-template"
    Type = "Launch Template"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "main" {
  name                = "${var.environment}-${var.app_name}-asg"
  vpc_zone_identifier = var.subnet_ids
  target_group_arns   = var.target_group_arns
  health_check_type   = var.health_check_type
  health_check_grace_period = var.health_check_grace_period

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }

  dynamic "tag" {
    for_each = var.common_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.environment}-${var.app_name}-asg"
    propagate_at_launch = true
  }

  tag {
    key                 = "Type"
    value               = "Auto Scaling Group"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Policies
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "${var.environment}-${var.app_name}-scale-up"
  scaling_adjustment     = var.scale_up_adjustment
  adjustment_type        = "ChangeInCapacity"
  cooldown               = var.scale_up_cooldown
  autoscaling_group_name = aws_autoscaling_group.main.name
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "${var.environment}-${var.app_name}-scale-down"
  scaling_adjustment     = var.scale_down_adjustment
  adjustment_type        = "ChangeInCapacity"
  cooldown               = var.scale_down_cooldown
  autoscaling_group_name = aws_autoscaling_group.main.name
}

# CloudWatch Alarms for Auto Scaling
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.environment}-${var.app_name}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = var.cpu_high_threshold
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.main.name
  }

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.app_name}-cpu-high-alarm"
    Type = "CloudWatch Alarm"
  })
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "${var.environment}-${var.app_name}-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = var.cpu_low_threshold
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.main.name
  }

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.app_name}-cpu-low-alarm"
    Type = "CloudWatch Alarm"
  })
}

# Application Load Balancer
resource "aws_lb" "main" {
  count = var.enable_load_balancer ? 1 : 0

  name               = "${var.environment}-${var.app_name}-alb"
  internal           = var.internal_load_balancer
  load_balancer_type = "application"
  security_groups    = var.alb_security_group_ids
  subnets            = var.alb_subnet_ids

  enable_deletion_protection = var.enable_deletion_protection

  access_logs {
    bucket  = var.alb_access_logs_bucket
    prefix  = var.alb_access_logs_prefix
    enabled = var.enable_alb_access_logs
  }

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.app_name}-alb"
    Type = "Application Load Balancer"
  })
}

# Target Group
resource "aws_lb_target_group" "main" {
  count = var.enable_load_balancer ? 1 : 0

  name     = "${var.environment}-${var.app_name}-tg"
  port     = var.target_group_port
  protocol = var.target_group_protocol
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = var.health_check_healthy_threshold
    unhealthy_threshold = var.health_check_unhealthy_threshold
    timeout             = var.health_check_timeout
    interval            = var.health_check_interval
    path                = var.health_check_path
    matcher             = var.health_check_matcher
    port                = "traffic-port"
    protocol            = var.target_group_protocol
  }

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.app_name}-target-group"
    Type = "Target Group"
  })
}

# Load Balancer Listener
resource "aws_lb_listener" "main" {
  count = var.enable_load_balancer ? 1 : 0

  load_balancer_arn = aws_lb.main[0].arn
  port              = var.listener_port
  protocol          = var.listener_protocol

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main[0].arn
  }

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.app_name}-listener"
    Type = "Load Balancer Listener"
  })
}

# HTTPS Listener (if SSL certificate is provided)
resource "aws_lb_listener" "https" {
  count = var.enable_load_balancer && var.ssl_certificate_arn != "" ? 1 : 0

  load_balancer_arn = aws_lb.main[0].arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = var.ssl_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main[0].arn
  }

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.app_name}-https-listener"
    Type = "HTTPS Load Balancer Listener"
  })
}

# IAM Role for EC2 instances
resource "aws_iam_role" "main" {
  name = "${var.environment}-${var.app_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.app_name}-ec2-role"
    Type = "IAM Role"
  })
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "main" {
  name = "${var.environment}-${var.app_name}-ec2-profile"
  role = aws_iam_role.main.name

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.app_name}-ec2-profile"
    Type = "IAM Instance Profile"
  })
}

# IAM Policy for EC2 instances
resource "aws_iam_role_policy" "main" {
  name = "${var.environment}-${var.app_name}-ec2-policy"
  role = aws_iam_role.main.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",
          "logs:PutLogEvents",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach AWS managed policies
resource "aws_iam_role_policy_attachment" "ssm_managed_instance_core" {
  role       = aws_iam_role.main.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent_server_policy" {
  count      = var.enable_cloudwatch_agent ? 1 : 0
  role       = aws_iam_role.main.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "main" {
  count = var.enable_cloudwatch_logs ? 1 : 0

  name              = "/aws/ec2/${var.environment}-${var.app_name}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_id

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.app_name}-log-group"
    Type = "CloudWatch Log Group"
  })
}

# SNS Topic for notifications
resource "aws_sns_topic" "main" {
  count = var.enable_sns_notifications ? 1 : 0

  name = "${var.environment}-${var.app_name}-notifications"
  kms_master_key_id = var.kms_key_id

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.app_name}-sns-topic"
    Type = "SNS Topic"
  })
}

# SNS Topic Subscription
resource "aws_sns_topic_subscription" "main" {
  count = var.enable_sns_notifications && var.sns_endpoint != "" ? 1 : 0

  topic_arn = aws_sns_topic.main[0].arn
  protocol  = var.sns_protocol
  endpoint  = var.sns_endpoint
}

# CloudWatch Alarms for SNS notifications
resource "aws_cloudwatch_metric_alarm" "instance_health" {
  count = var.enable_sns_notifications ? 1 : 0

  alarm_name          = "${var.environment}-${var.app_name}-instance-health"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "This metric monitors instance health"
  alarm_actions       = [aws_sns_topic.main[0].arn]

  dimensions = {
    TargetGroup  = aws_lb_target_group.main[0].arn_suffix
    LoadBalancer = aws_lb.main[0].arn_suffix
  }

  tags = merge(var.common_tags, {
    Name = "${var.environment}-${var.app_name}-instance-health-alarm"
    Type = "CloudWatch Alarm"
  })
}
