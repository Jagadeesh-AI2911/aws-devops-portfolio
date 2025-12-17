# 1. Database Subnet Group
resource "aws_db_subnet_group" "main" {
  count      = var.instance_count > 0 ? 1 : 0 # Only create if active
  name       = "${var.environment}-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = { Name = "${var.environment}-db-subnet-group" }
}

# 2. Database Security Group
resource "aws_security_group" "db_sg" {
  count       = var.instance_count > 0 ? 1 : 0
  name        = "${var.environment}-db-sg"
  description = "Allow MySQL traffic from App Server only"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    # Only allow traffic from the ASG Security Group (if it exists)
    security_groups = var.instance_count > 0 ? [aws_security_group.alb_sg.id] : [] 
    # Note: In a real app, this should link to the ASG SG, not ALB SG, but we simplified SG logic in main.tf
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 3. The Database Instance
resource "aws_db_instance" "default" {
  count                  = var.instance_count > 0 ? 1 : 0
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  identifier             = "${var.environment}-db"
  db_name                = "appdb"
  username               = "adminuser"
  password               = var.db_password
  
  db_subnet_group_name   = aws_db_subnet_group.main[0].name
  vpc_security_group_ids = [aws_security_group.db_sg[0].id]
  
  multi_az               = false
  publicly_accessible    = false
  skip_final_snapshot    = true
  storage_encrypted      = true 
  
  tags = { Name = "${var.environment}-database" }
}