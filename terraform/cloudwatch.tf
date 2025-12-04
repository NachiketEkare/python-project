// cpu alarm

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "ECS-HighCPU"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  threshold           = 70
  period              = 60
  statistic           = "Average"

  metric_name = "CPUUtilization"
  namespace   = "AWS/ECS"

  alarm_description = "CPU usage exceeded 70%"
}

// unhealthy target alarm

resource "aws_cloudwatch_metric_alarm" "alb_unhealthy" {
  alarm_name          = "ALB-UnhealthyTargets"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  threshold           = 1
  period              = 60
  statistic           = "Average"

  metric_name = "UnHealthyHostCount"
  namespace   = "AWS/ApplicationELB"

  alarm_description = "ALB has unhealthy targets"
}
