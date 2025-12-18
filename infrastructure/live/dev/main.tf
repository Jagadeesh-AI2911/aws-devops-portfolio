module "portfolio" {
  source = "../../modules/portfolio-app"

  environment     = var.env_name
  vpc_cidr        = var.vpc_cidr
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
  instance_count  = var.instance_count
  
  # Logic: If it's dev, I usually want the ALB enabled
  enable_alb      = true 
  
  db_password     = var.db_password
}