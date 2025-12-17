# 1. Security Groups (Simplified for brevity)
resource "aws_security_group" "alb_sg" {
  vpc_id = aws_vpc.main.id
  ingress { 
    from_port = 80 
    to_port = 80 
    protocol = "tcp" 
    cidr_blocks = ["0.0.0.0/0"] 
    }
  egress  { 
    from_port = 0  
    to_port = 0  
    protocol = "-1"  
    cidr_blocks = ["0.0.0.0/0"] 
    }
}

# 2. Load Balancer (Only created if enable_alb = true)
resource "aws_lb" "app" {
  count              = var.enable_alb ? 1 : 0
  name               = "${var.environment}-alb"
  load_balancer_type = "application"
  subnets            = aws_subnet.public[*].id
  security_groups    = [aws_security_group.alb_sg.id]
}

# 3. Auto Scaling Group
resource "aws_autoscaling_group" "app" {
  desired_capacity    = var.instance_count
  max_size            = var.instance_count + 1
  min_size            = var.instance_count
  vpc_zone_identifier = aws_subnet.public[*].id
  
  # Only attach to ALB if ALB exists
  target_group_arns = var.enable_alb ? [aws_lb_target_group.app[0].arn] : []

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }
}

resource "aws_launch_template" "app" {
  name_prefix   = "${var.environment}-app-"
  image_id      = "ami-0c7217cdde317cfec" # Amazon Linux 2023 (US-East-1)
  instance_type = "t2.micro"
}