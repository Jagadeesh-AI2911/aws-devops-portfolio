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
    description = "allow all outbound"
  }
}

# -------------------------------------------------------------
# The Web Server (Compute Layer)
# -------------------------------------------------------------


# 9. Dynamic AMI Lookup (Get latest Amazon Linux 2023)
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# 10. The Web Server Instance
resource "aws_instance" "web_server" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro" 
  subnet_id     = aws_subnet.public.id

  # Security Group: We use the ALB SG for now because it allows HTTP from Anywhere.
  # In a later step (Day 4), we will move this to the App SG when we add a Load Balancer.
  vpc_security_group_ids = [aws_security_group.alb_sg.id]

  # User Data: This script runs ONLY once when the instance starts.
  # It installs Nginx and creates a custom HTML page.
  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y nginx
              systemctl start nginx
              systemctl enable nginx
              echo "<h1>Deployed via Terraform</h1><p>Welcome to Jagadeesh's Portfolio Project!</p>" > /usr/share/nginx/html/index.html
              EOF

  tags = {
    Name = "portfolio-web-server"
  }
}

# 11. Output the URL (So you can click it easily)
output "web_server_url" {
  value       = "http://${aws_instance.web_server.public_ip}"
  description = "Click the URL to see deployed website"
}