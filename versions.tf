terraform {
  # Require a reasonably recent Terraform version
  required_version = ">= 1.5.0"

  # Pin the AWS provider major version (v5+)
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  # AWS region is controlled by variables.tf / terraform.tfvars
  region = var.aws_region

  # Optional, but best practice for portfolio projects:
  # ensures all resources get consistent tags without repeating everywhere.
  default_tags {
    tags = {
      Project   = "ha-webapp-terraform"
      ManagedBy = "Terraform"
    }
  }
}
