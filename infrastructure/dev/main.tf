provider "aws" {
  region = "us-east-1"
}

# -------------------------------------------------------------
# 1. NETWORKING LAYER (VPC & Subnets)
# -------------------------------------------------------------

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "portfolio-vpc"
    Environment = "dev"
    Project = "portfolio"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

# Subnet 1 (Zone A)
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = { 
    Name = "portfolio-public-subnet-1" 
    Environment = "dev"
    Project = "portfolio"
  }
}

# Subnet 2 (Zone B) - REQUIRED for Load Balancer High Availability
resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.3.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1b"

  tags = { 
    Name = "portfolio-public-subnet-2" 
    Environment = "dev"
    Project = "portfolio"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "portfolio-public-route-table"
    Environment = "dev"
    Project = "portfolio"
  }
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public_rt.id
  depends_on     = [aws_route_table.public_rt]
  
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public_rt.id
  depends_on     = [aws_route_table.public_rt]
}

# -------------------------------------------------------------
# 2. SECURITY LAYER (Firewalls)
# -------------------------------------------------------------

resource "aws_security_group" "alb_sg" {
  name        = "portfolio-alb-sg"
  description = "Allow HTTP from Anywhere"
  vpc_id      = aws_vpc.main.id
  depends_on  = [aws_vpc.main]
  tags = {
    Name = "portfolio-alb-sg"
    Environment = "dev"
    Project = "portfolio"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "asg_sg" {
  name        = "portfolio-asg-sg"
  description = "Allow HTTP from ALB only"
  vpc_id      = aws_vpc.main.id
  depends_on  = [aws_vpc.main]
  tags = {
    Name = "portfolio-asg-sg"
    Environment = "dev"
    Project = "portfolio"
  }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# -------------------------------------------------------------
# 3. COMPUTE LAYER (Launch Template & ASG)
# -------------------------------------------------------------

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
  tags = {
    Name = "Lates-AMI"
    Environment = "dev"
    Project = "portfolio"
  }
}

# The "Blueprint" for our servers
resource "aws_launch_template" "app_lt" {
  name_prefix   = "portfolio-app-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.asg_sg.id]
  }

  # Installs Nginx and creates a dynamic HTML page with the server's ID
  user_data = base64encode(<<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y nginx
              systemctl start nginx
              systemctl enable nginx
              INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
              echo "<h1>High Availability Cluster</h1><p>Served by instance: $INSTANCE_ID</p>" > /usr/share/nginx/html/index.html
              EOF
  )
  tags = {
    Name = "portfolio-app-lt"
    Environment = "dev"
    Project = "portfolio"
  }
}

# The "Manager" that ensures 2 servers are always running
resource "aws_autoscaling_group" "app_asg" {
  desired_capacity    = 2
  max_size            = 3
  min_size            = 1
  vpc_zone_identifier = [aws_subnet.public_1.id, aws_subnet.public_2.id]
  target_group_arns   = [aws_lb_target_group.app_tg.arn]

  launch_template {
    id      = aws_launch_template.app_lt.id
    version = "$Latest"
  }
  
  # Wait for instance to be healthy before considering it "Done"
  health_check_type         = "ELB"
  health_check_grace_period = 300
  default_cooldown          = 10
}

# -------------------------------------------------------------
# 4. LOAD BALANCING LAYER (ALB)
# -------------------------------------------------------------

resource "aws_lb" "app_alb" {
  name               = "portfolio-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]
  depends_on         = [aws_security_group.alb_sg]
  tags = {
    Name = "portfolio-alb"
    Environment = "dev"
    Project = "portfolio"
  }
}

resource "aws_lb_target_group" "app_tg" {
  name     = "portfolio-app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
  depends_on = [aws_lb.app_alb]
  tags = {
    Name = "portfolio-app-tg"
    Environment = "dev"
    Project = "portfolio"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
  depends_on = [aws_lb_target_group.app_tg]
  tags = {
    Name = "portfolio-alb-listener"
    Environment = "dev"
    Project = "portfolio"
  }
}

# -------------------------------------------------------------
# 5. OUTPUTS
# -------------------------------------------------------------
output "alb_dns_name" {
  value       = "http://${aws_lb.app_alb.dns_name}"
  description = "The Public URL of your Load Balancer"
}