provider "aws" {
  region = "us-east-1"
}

# ----------------------
# Networking Layer
# ----------------------

# 1. vpc
resource "aws_vpc" "main" {
  cidr_block            = "10.0.0.0/16"
  enable_dns_support    = true
  enable_dns_hostnames  = true
  tags = {
    Name = "portfolio-vpc"
    Environment = "dev"
    Project = "portfolio"
  }
}

# 2. IGW
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "portfolio-igw"
    Environment = "dev"
    Project = "portfolio"
  }
}

# 3. Public Subnet

resource "aws_subnet" "Public" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-east-1a"
  tags = {
    Name = "portfolio-public-subnet"
    Environment = "dev"
    Project = "portfolio"
  }
}

# 4. Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "portfolio-public-route"
    Environment = "dev"
    Project = "portfolio"
  }
}

# 5. Route Table Association

resource "aws_route_table_association" "public_rt" {
  subnet_id = aws_subnet.Public.id
  route_table_id = aws_route_table.public_rt.id
}


# -------------------------
# Security & Private Layer
# -------------------------

# 1. Security Group: load balancer (public)
resource "aws_security_group" "portfolio_alb_sg" {
  name = "portfolio-sg"
  description = "portfolio security group allo http inbound traffic"
  vpc_id = aws_vpc.main.id
  ingress {
    description = "HTTP from internet"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "portfolio-sg"
    Environment = "dev"
    Project = "portfolio"
  }
}

# 2. private subnet
resource "aws_subnet" "private" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "portfolio-private-subnet"
    Environment = "dev"
    Project = "portfolio"
  }
}

# 3. security group: ec2 (private)
resource "aws_security_group" "app_sg" {
  name = "portfolio-app-sg"
  description = "portfolio security group allow traffic from ALB only"
  vpc_id = aws_vpc.main.id
  ingress {
    description = "HTTP from ALB"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    security_groups = [aws_security_group.portfolio_alb_sg.id] # allow traffic from ALB only
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}