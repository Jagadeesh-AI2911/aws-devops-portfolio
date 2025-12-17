module "portfolio" {
  source = "../../modules/portfolio-app"

  environment     = "prod"
  vpc_cidr        = "10.1.0.0/16" # Different IP range than Dev
  public_subnets  = ["10.1.1.0/24", "10.1.2.0/24"]
  private_subnets = ["10.1.3.0/24", "10.1.4.0/24"]

  # COST SAVING SETTINGS
  instance_count  = 0      # Runs 0 servers ($0 cost)
  enable_alb      = false  # Skips Load Balancer ($0 cost)
  db_password     = "prodpass123"
}