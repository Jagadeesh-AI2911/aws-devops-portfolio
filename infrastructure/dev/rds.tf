# 1. database subnet group (this tells RDS to use only these subnets)

resource "aws_db_subnet_group" "main" {
    name        = "portfolio-db-subnet-group"
    subnet_ids  = [aws_subnet.private_1.id, aws_subnet.private_2.id]
    tags = {
        Name            = "portfolio-db-subnet-group"
        Environment     = "dev"
        Project         = "portfolio"
    }
}

resource "aws_security_group" "db_sg" {
    name            = "portfolio-db-sg"
    description     = "allow MySQL traffic from App server only"
    vpc_id          = aws_vpc.main.id

    ingress {
        description     = "MySQL from App Layer"
        from_port       = 3306
        to_port         = 3306
        security_groups = [aws_security_group.asg_sg.id]
        protocol        = "tcp"
    }

    egress {
        from_port       = 0
        to_port         = 0
        protocol        = "-1"
        cidr_blocks     = ["0.0.0.0/0"]
    }
}

resource "aws_db_instance" "default" {
    allocated_storage       = 20
    storage_type            = "gp2"
    engine                  = "mysql"
    engine_version          = "8.0"
    instance_class          = "db.t3.micro"
    identifier              = "portfolio-db"
    db_name                 = "appdb"
    username                = "adminuser"
    password                = "securepassword123"
    db_subnet_group_name    = aws_db_subnet_group.main.name
    vpc_security_group_ids  = [aws_security_group.db_sg.id]
    multi_az                = false
    publicly_accessible     = false
    skip_final_snapshot     = true
    tags = {
        Name        = "portfolio-database"
        Environment = "dev"
        Project     = "portfolio"
    }
}