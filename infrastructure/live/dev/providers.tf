provider "aws" {
  region = "us-east-1"
  
  # Useful tag for cost allocation tracking
  default_tags {
    tags = {
      Environment = "dev"
      Project     = "portfolio-app"
      ManagedBy   = "terraform"
    }
  }
}