terraform {
  backend "s3" {
    bucket         = "jagadeesh-portfolio-tf-state-prod-bkt"  # <--- REPLACE THIS
    key            = "prod/terraform.tfstate"     # <--- Note the "prod" folder
    region         = "us-east-1"
    dynamodb_table = "portfolio-tf-locks"
    encrypt        = true
  }
}