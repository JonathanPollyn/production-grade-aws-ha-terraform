# ==========================================================
# Security Groups
# Matches your diagram security flow:
# - Internet -> ALB (80)
# - ALB -> EC2 instances (app_port, default 80)
# - EC2 instances -> RDS Postgres (5432)
# - EC2 instances -> EFS (2049)
# ==========================================================

# ALB SG: allows inbound HTTP from the internet
resource "aws_security_group" "alb" {
  name        = "${var.name}-sg-alb"
  description = "ALB security group"
  vpc_id      = aws_vpc.this.id

  # Internet -> ALB on HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ALB needs outbound access to reach targets (EC2)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${var.name}-sg-alb" })
}

# App SG: only allows inbound traffic from the ALB on app_port
resource "aws_security_group" "app" {
  name        = "${var.name}-sg-app"
  description = "EC2 App instances security group"
  vpc_id      = aws_vpc.this.id

  # ALB -> EC2 instances on the app port (80 by default)
  ingress {
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # Optional SSH (ONLY if you set key_name). For best practice, keep key_name blank and use SSM instead.
  dynamic "ingress" {
    for_each = var.key_name != "" ? [1] : []
    content {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  # Outbound allowed so instances can reach:
  # - RDS (5432)
  # - EFS (2049)
  # - yum updates via NAT
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${var.name}-sg-app" })
}

# DB SG: ONLY allow inbound Postgres from the app SG
resource "aws_security_group" "db" {
  name        = "${var.name}-sg-db"
  description = "RDS PostgreSQL security group"
  vpc_id      = aws_vpc.this.id

  # EC2 (app) -> RDS Postgres
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  # Outbound is typically left open for managed services; still private due to subnet + no public access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${var.name}-sg-db" })
}

# EFS SG: only allows NFS from app instances
resource "aws_security_group" "efs" {
  name        = "${var.name}-sg-efs"
  description = "EFS security group"
  vpc_id      = aws_vpc.this.id

  # EC2 (app) -> EFS on NFS
  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  # Outbound open is fine; security is controlled by inbound + subnet boundaries
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${var.name}-sg-efs" })
}
