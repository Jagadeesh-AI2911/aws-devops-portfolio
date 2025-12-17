terraform {
  backend "s3" {
    bucket         = "jagadeesh-portfolio-tf-state-bkt"  # <--- REPLACE THIS
    key            = "dev/terraform.tfstate"      # <--- Note the "dev" folder
    region         = "us-east-1"
    dynamodb_table = "portfolio-tf-locks"
    encrypt        = true
  }
}