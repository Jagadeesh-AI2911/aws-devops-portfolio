variable "env_name" {
  description = "Environment name (dev, prod)"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR Block"
  type        = string
}

variable "public_subnets" {
  description = "List of public subnet CIDRs"
  type        = list(string)
}

variable "private_subnets" {
  description = "List of private subnet CIDRs"
  type        = list(string)
}

variable "instance_count" {
  description = "Number of EC2 instances to launch"
  type        = number
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}