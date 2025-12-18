output "alb_url" {
  description = "The Public URL of the Load Balancer"
  value       = module.portfolio.alb_dns_name
}

output "db_endpoint" {
  description = "The Private Endpoint of the Database"
  value       = module.portfolio.db_endpoint
}