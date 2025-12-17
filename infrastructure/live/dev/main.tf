module "portfolio" {
  source = "../../modules/portfolio-app"

  environment     = "dev"
  vpc_cidr        = "10.0.0.0/16"
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]

  # ACTIVE SETTINGS
  instance_count  = 1      # Runs 1 server (Free Tier)
  enable_alb      = true   # Creates Load Balancer
  db_password     = "devpass123"
}