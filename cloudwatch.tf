resource "aws_cloudwatch_metric_alarm" "pocketbase_ebs_usage" {
  alarm_name          = "EBSVolumeUtilizationAlarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "VolumeUsage"
  namespace           = "AWS/EBS"
  period              = 60
  statistic           = "Average"
  threshold           = 90
  alarm_description   = "EBS Volume Usage > 90% for 2 consecutive minutes"
  alarm_actions       = [aws_sns_topic.email_topic.arn]
  dimensions = {
    VolumeId = aws_volume_attachment.pocketbase.volume_id
  }
  tags = merge(var.common_tags, {
    name = "ebs_utilisation_alarm"
  })
}

resource "aws_cloudwatch_metric_alarm" "pocketbase_ec2_memory_alarm" {
  alarm_name          = "MemoryUtilizationAlarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "System/Linux"
  period              = 60
  statistic           = "Average"
  threshold           = 90
  alarm_description   = "Memory Utilization > 90% for 2 consecutive minutes"
  alarm_actions       = [aws_sns_topic.email_topic.arn]
  dimensions = {
    InstanceId = aws_instance.pocketbase.id
  }
  tags = merge(var.common_tags, {
    name = "ebs_utilisation_alarm"
  })
}

resource "aws_cloudwatch_metric_alarm" "pocketbase_ec2_cpu_alarm" {
  alarm_name          = "CPUUtilizationAlarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 90
  alarm_description   = "CPU Utilization > 90% for 2 consecutive minutes"
  alarm_actions       = [aws_sns_topic.email_topic.arn]
  dimensions = {
    InstanceId = aws_instance.pocketbase.id
  }
  tags = merge(var.common_tags, {
    name = "ebs_utilisation_alarm"
  })
}
