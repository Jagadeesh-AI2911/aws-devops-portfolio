variable "environment" { type = string }
variable "vpc_cidr" { type = string }
variable "public_subnets" { type = list(string) }
variable "private_subnets" { type = list(string) }
variable "instance_count" { type = number }  # Control server count
variable "enable_alb" { type = bool }        # Turn off ALB to save $0.50/day
variable "db_password" { 
    type = string
    sensitive = true 
    description = "Password for the database"
}