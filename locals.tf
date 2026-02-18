# Fetch available AZs in the selected region (var.aws_region)
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  # Use the first N AZs (this project assumes 2 AZs)
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  # Standard tags applied to most resources
  common_tags = merge(
    {
      Project   = var.name
      ManagedBy = "Terraform"
    },
    var.tags
  )
}

