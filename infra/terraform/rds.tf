# ==============================================================================
# PROJECTIFY — TERRAFORM RDS POSTGRESQL CONFIGURATION
# ==============================================================================
#
# PURPOSE:
#   Provisions an Amazon RDS PostgreSQL database instance isolated inside
#   private subnets. Access is restricted exclusively to EKS worker nodes.
# ==============================================================================

# Subnet Group placing RDS in Private Subnets across Multi-AZ
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

# Security Group restricting Database Port 5432 access to VPC instances
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "Security group for PostgreSQL RDS database instance"
  vpc_id      = aws_vpc.main.id

  # Allow inbound PostgreSQL connection on port 5432 from VPC CIDR
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-rds-sg"
  }
}

# RDS PostgreSQL Instance
resource "aws_db_instance" "main" {
  identifier           = "${var.project_name}-db"
  allocated_storage    = var.db_allocated_storage
  max_allocated_storage = 100 # Auto-scaling storage limit
  engine               = "postgres"
  engine_version       = "16.3"
  instance_class       = "db.t4g.micro" # Cost-efficient ARM instance
  db_name              = var.db_name
  username             = var.db_username
  password             = var.db_password
  db_subnet_group_name = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  skip_final_snapshot    = true
  publicly_accessible    = false # Isolated inside private subnet

  tags = {
    Name = "${var.project_name}-postgres-db"
  }
}
