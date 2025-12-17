provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Environment = "prod"
      Project     = "portfolio-app"
      ManagedBy   = "terraform"
    }
  }
}