output "alb_url" {
  description = "The Public URL of the Load Balancer"
  value       = modules.portfolio-app.alb_dns_name
}

output "db_endpoint" {
  description = "The Private Endpoint of the Database"
  value       = modules.portfolio-app.db_endpoint
}