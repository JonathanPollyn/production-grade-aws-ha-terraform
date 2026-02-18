# ==========================================================
# EFS (Shared Storage)
# One EFS file system
# Mount targets in each AZ (in the private app subnets)
# Only EC2 instances (app SG) can access via NFS 2049
# ==========================================================

# Creates the EFS file system (regional service)
resource "aws_efs_file_system" "this" {
  # Encrypt data at rest
  encrypted = true

  tags = merge(local.common_tags, {
    Name = "${var.name}-efs"
  })
}

# Creates one mount target per subnet (one per AZ)
# This is what makes EFS reachable from EC2 instances in both AZs.
resource "aws_efs_mount_target" "this" {
  for_each = aws_subnet.private_app

  file_system_id = aws_efs_file_system.this.id
  subnet_id      = each.value.id

  # Attach the EFS security group that only allows NFS from the app instances SG
  security_groups = [aws_security_group.efs.id]
}
