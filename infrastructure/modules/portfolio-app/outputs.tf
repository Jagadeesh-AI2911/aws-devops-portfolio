output "alb_dns_name" {
  description = "The Public URL of the Load Balancer"
  value = var.enable_alb ? "http://${aws_lb.app[0].dns_name}" : "ALB Disabled"
}

output "db_endpoint" {
  description = "The Private Endpoint of the Database"
  value       = var.instance_count > 0 ? aws_db_instance.default[0].endpoint : "Database Disabled"
}

output "vpc_id" {
  value = aws_vpc.main.id
}