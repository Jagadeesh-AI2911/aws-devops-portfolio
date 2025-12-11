terraform {
    backend "s3" {
        bucket = "jagadeesh-portfolio-tf-state-bkt"
        key = "global/s3/terraform.tfstate"
        region = "us-east-1"
        dynamodb_table = "portfolio-tf-locks"
        encrypt = true
    }
}