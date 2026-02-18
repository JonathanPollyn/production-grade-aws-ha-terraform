# ==========================================================
# Global / Naming
# ==========================================================
variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "name" {
  description = "Prefix used for naming AWS resources."
  type        = string
  default     = "ha-aws-terraform"
}

variable "tags" {
  description = "Extra tags to apply to resources."
  type        = map(string)
  default     = {}
}

# ==========================================================
# Networking
# ==========================================================
variable "vpc_cidr" {
  description = "CIDR range for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "How many Availability Zones to use (this project assumes 2)."
  type        = number
  default     = 2

  validation {
    condition     = var.az_count == 2
    error_message = "This project is designed for 2 AZs (az_count must be 2)."
  }
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs (ALB goes here). Must have 2 entries."
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24"]

  validation {
    condition     = length(var.public_subnet_cidrs) == 2
    error_message = "public_subnet_cidrs must contain exactly 2 CIDRs."
  }
}

variable "private_app_subnet_cidrs" {
  description = "Private app subnet CIDRs (EC2/ASG goes here). Must have 2 entries."
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]

  validation {
    condition     = length(var.private_app_subnet_cidrs) == 2
    error_message = "private_app_subnet_cidrs must contain exactly 2 CIDRs."
  }
}

variable "private_db_subnet_cidrs" {
  description = "Private DB subnet CIDRs (RDS goes here). Must have 2 entries."
  type        = list(string)
  default     = ["10.0.20.0/24", "10.0.21.0/24"]

  validation {
    condition     = length(var.private_db_subnet_cidrs) == 2
    error_message = "private_db_subnet_cidrs must contain exactly 2 CIDRs."
  }
}

# ==========================================================
# Compute (EC2 / ASG)
# ==========================================================
variable "instance_type" {
  description = "EC2 instance type used in the Auto Scaling Group."
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Optional EC2 key pair name. Leave blank to avoid SSH access."
  type        = string
  default     = ""
}

variable "enable_ssm" {
  description = "Attach SSM permissions so you can connect without SSH."
  type        = bool
  default     = true
}

variable "asg_min" {
  description = "Minimum number of instances in the Auto Scaling Group."
  type        = number
  default     = 2
}

variable "asg_max" {
  description = "Maximum number of instances in the Auto Scaling Group."
  type        = number
  default     = 4
}

variable "asg_desired" {
  description = "Desired number of instances in the Auto Scaling Group."
  type        = number
  default     = 2
}

variable "app_port" {
  description = "Port the web app listens on (ALB forwards to this port)."
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "ALB health check endpoint served by the instances."
  type        = string
  default     = "/health"
}

# ==========================================================
# Database (RDS PostgreSQL, Multi-AZ)
# ==========================================================
variable "db_engine" {
  description = "RDS engine. Diagram uses PostgreSQL."
  type        = string
  default     = "postgres"
}

variable "db_engine_version" {
  description = "PostgreSQL engine version."
  type        = string
  default     = "15.5"
}

variable "db_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Initial database name created in RDS."
  type        = string
  default     = "medicarehub"
}

variable "db_username" {
  description = "Master username for the database."
  type        = string
  default     = "postgresadmin"
}

variable "db_password" {
  description = "Master password for the database (only used if db_password_ssm_parameter_name is null)."
  type        = string
  sensitive   = true
  default     = null
}

variable "db_password_ssm_parameter_name" {
  description = "Optional SSM Parameter Store name containing the DB password (SecureString). If set, it overrides db_password."
  type        = string
  default     = null
}

variable "db_multi_az" {
  description = "Enable Multi-AZ deployment (Primary + Standby)."
  type        = bool
  default     = true
}

variable "db_deletion_protection" {
  description = "Prevents accidental deletion of the DB instance."
  type        = bool
  default     = false
}

variable "db_skip_final_snapshot" {
  description = "Skip final snapshot on destroy (true is common for labs)."
  type        = bool
  default     = true
}

variable "db_final_snapshot_identifier" {
  description = "Final snapshot identifier used if db_skip_final_snapshot=false."
  type        = string
  default     = "ha-aws-final-snapshot"
}

# ==========================================================
# Route 53 (Optional)
# ==========================================================
variable "enable_route53" {
  description = "If true, create Route53 record(s). Set false if Route53 is not available in your account."
  type        = bool
  default     = false
}

variable "domain_name" {
  description = "Domain name to create record for (example: app.example.com)."
  type        = string
  default     = ""
}

variable "hosted_zone_id" {
  description = "Route53 hosted zone ID."
  type        = string
  default     = ""
}

# ==========================================================
# S3 (Optional use in your project)
# ==========================================================
variable "enable_s3_site" {
  description = "Create an S3 bucket and upload static site files (index.html, style.css)."
  type        = bool
  default     = true
}
