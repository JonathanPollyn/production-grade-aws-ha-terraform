# ==========================================================
# IAM for EC2 App Instances
# Purpose:
# - Allow EC2 instances to assume a role (required for any instance profile)
# - Optionally enable SSM Session Manager (no SSH required)
# ==========================================================

# Trust policy: allows EC2 service to assume this role
data "aws_iam_policy_document" "ec2_assume" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# IAM Role attached to the EC2 instances (via instance profile)
resource "aws_iam_role" "app" {
  name               = "${var.name}-role-app"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json

  tags = local.common_tags
}

# Instance Profile is what EC2 actually attaches (role is inside the profile)
resource "aws_iam_instance_profile" "app" {
  name = "${var.name}-profile-app"
  role = aws_iam_role.app.name
}

# Optional: enables AWS Systems Manager (SSM) so you can connect without SSH
# This is best practice for private subnets.
resource "aws_iam_role_policy_attachment" "ssm" {
  count      = var.enable_ssm ? 1 : 0
  role       = aws_iam_role.app.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
