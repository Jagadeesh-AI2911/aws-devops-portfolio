# -------------------------------------------------------------
# 1. SECURITY GROUPS
# -------------------------------------------------------------
resource "aws_security_group" "alb_sg" {
  name        = "${var.environment}-alb-sg"
  description = "Allow HTTP from Anywhere"
  vpc_id      = aws_vpc.main.id

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
  name        = "${var.environment}-asg-sg"
  description = "Allow HTTP from ALB only"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    # Allow traffic from the ALB SG (if ALB exists), otherwise open to VPC
    security_groups = var.enable_alb ? [aws_security_group.alb_sg.id] : []
    cidr_blocks     = var.enable_alb ? [] : [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# -------------------------------------------------------------
# 2. LOAD BALANCER 
# -------------------------------------------------------------
resource "aws_lb" "app" {
  count              = var.enable_alb ? 1 : 0
  name               = "${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = aws_subnet.public[*].id
}

resource "aws_lb_target_group" "app" {
  count    = var.enable_alb ? 1 : 0
  name     = "${var.environment}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "http" {
  count             = var.enable_alb ? 1 : 0
  load_balancer_arn = aws_lb.app[0].arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app[0].arn
  }
}

# -------------------------------------------------------------
# 3. COMPUTE (ASG & Launch Template)
# -------------------------------------------------------------
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

resource "aws_launch_template" "app" {
  name_prefix   = "${var.environment}-app-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.asg_sg.id]
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y nginx
              systemctl start nginx
              systemctl enable nginx
              TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
              INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/instance-id)
              echo "<h1>${var.environment} Environment</h1><p>Served by: $INSTANCE_ID</p>" > /usr/share/nginx/html/index.html
              EOF
  )
}

resource "aws_autoscaling_group" "app" {
  desired_capacity    = var.instance_count
  max_size            = var.instance_count + 1
  min_size            = var.instance_count
  vpc_zone_identifier = aws_subnet.public[*].id
  # Only attach to ALB if ALB is enabled
  target_group_arns   = var.enable_alb ? [aws_lb_target_group.app[0].arn] : []

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }
  # If using ALB, wait for ELB checks. If not, rely on EC2 checks.
  health_check_type         = var.enable_alb ? "ELB" : "EC2"
  health_check_grace_period = 300
}