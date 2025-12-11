provider "aws" {
  region = "us-east-1"
}

# 1. S3 Bucket to store the state file
resource "aws_s3_bucket" "terraform_state" {
  bucket = "jagadeesh-portfolio-tf-state-bkt" 
  # Prevent accidental deletion of this bucket
  lifecycle {
    prevent_destroy = true
  }
  tags = {
    Name = "jagadeesh-portfolio-tf-state-bkt"
    Environment = "dev"
    Project = "portfolio"
  }
}

# Enable Versioning
resource "aws_s3_bucket_versioning" "enabled" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 2. DynamoDB Table for Locking
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "portfolio-tf-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

# Outputs to copy/paste later
output "bucket_name" {
  value = aws_s3_bucket.terraform_state.bucket
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.terraform_locks.name
}