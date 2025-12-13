# -------------------------------------------------------------
# CLOUDWATCH MONITORING (Free Tier)
# -------------------------------------------------------------

# Alarm: Trigger if CPU goes above 80% for 2 periods of 120 seconds
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "portfolio-high-cpu-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "This metric monitors ec2 cpu utilization"
  
  # Connecting this alarm to the Auto Scaling Group
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_asg.name
  }

  # In production, I will add an 'alarm_actions' here to trigger SNS (Email)
  # or Auto Scaling Policies (Scale Out).
}