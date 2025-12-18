module "portfolio" {
  source = "../../modules/portfolio-app"

  environment     = var.env_name
  vpc_cidr        = var.vpc_cidr
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
  instance_count  = var.instance_count
  
  # Logic: Prod is passive, so no ALB
  enable_alb      = false
  
  db_password     = var.db_password
}