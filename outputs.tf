# ==========================================================
# Outputs
# These make testing and validation easier after terraform apply
# ==========================================================

output "alb_dns_name" {
  description = "Public entry point. Use this to test the app if Route 53 is disabled."
  value       = aws_lb.this.dns_name
}

output "rds_endpoint" {
  description = "RDS endpoint hostname (private). Connect from inside the VPC (SSM tunnel/bastion)."
  value       = aws_db_instance.this.address
}

output "rds_port" {
  description = "RDS port (PostgreSQL default is 5432)."
  value       = aws_db_instance.this.port
}

output "rds_db_name" {
  description = "Initial database name created on the RDS instance."
  value       = var.db_name
}

output "efs_id" {
  description = "EFS file system ID (shared storage)."
  value       = aws_efs_file_system.this.id
}

output "s3_bucket_name" {
  description = "S3 bucket where index.html + style.css are uploaded (private)."
  value       = var.enable_s3_site ? aws_s3_bucket.site[0].bucket : null
}
