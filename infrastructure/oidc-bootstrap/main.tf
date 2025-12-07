provider "aws" {
  region = "us-east-1"
}

# 1. The Virtual Private Cloud (VPC)
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "portfolio-vpc"
    Environment = "dev"
    Project     = "aws-devops-portfolio"
  }
}

# 2. Internet Gateway (IGW) - To talk to the internet
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "portfolio-igw"
  }
}

# 3. Public Subnet (Where the Load Balancer lives)
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true # Instances get public IPs automatically
  availability_zone       = "us-east-1a"

  tags = {
    Name = "portfolio-public-subnet"
  }
}

# 4. Route Table (The GPS for traffic)
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "portfolio-public-rt"
  }
}

# 5. Associate Route Table with Subnet
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}