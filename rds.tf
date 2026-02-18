# ==========================================================
# RDS (PostgreSQL Multi-AZ)
# RDS Primary + Standby (Multi-AZ) managed by AWS
# Deployed in private DB subnets
# Only reachable from EC2 app instances (via SG)
# ==========================================================

resource "aws_db_subnet_group" "this" {
  name = "${var.name}-db-subnets"

  # private_db is a map because subnets were created with for_each
  subnet_ids = [for s in values(aws_subnet.private_db) : s.id]

  tags = merge(local.common_tags, { Name = "${var.name}-db-subnets" })
}

resource "aws_db_instance" "this" {
  identifier = "${var.name}-db"

  # Engine settings (let AWS pick the default engine version for the region)
  engine         = var.db_engine # postgres
  instance_class = var.db_instance_class

  # Storage
  allocated_storage = 20
  storage_encrypted = true

  # Multi-AZ (Primary + Standby). AWS manages the standby instance automatically.
  multi_az = var.db_multi_az

  # Networking
  publicly_accessible    = false
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.db.id]

  # DB credentials
  db_name  = var.db_name
  username = var.db_username

  # If you later switch to SSM Parameter Store, we can update this safely.
  password = var.db_password

  # Backups
  backup_retention_period = 7

  # Safe destroy controls (prevents the "snapshot already exists" error)
  deletion_protection = var.db_deletion_protection
  skip_final_snapshot = var.db_skip_final_snapshot

  # Only used when skip_final_snapshot = false
  final_snapshot_identifier = var.db_skip_final_snapshot ? null : var.db_final_snapshot_identifier

  # Let AWS apply minor patches automatically (recommended)
  auto_minor_version_upgrade = true

  lifecycle {
    # Since AWS chooses the engine_version when not provided, ignore drift
    ignore_changes = [engine_version]
  }

  tags = merge(local.common_tags, { Name = "${var.name}-rds" })
}
