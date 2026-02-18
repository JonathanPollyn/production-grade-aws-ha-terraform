# ==========================================================
# ASG + Launch Template (EC2 Web Tier)
# Matches your diagram:
# - EC2 instances in private app subnets across 2 AZs
# - Auto Scaling Group attached to ALB target group
# - User data installs Apache, writes /health, deploys index.html/style.css
# - Mounts EFS for shared storage
# ==========================================================

# ----------------------------
# Amazon Linux 2 AMI via SSM (most reliable per region)
# ----------------------------
data "aws_ssm_parameter" "al2_ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

locals {
  # Read local website files and base64 encode them so they can be embedded in user_data safely
  index_html_b64 = base64encode(file("${path.module}/web/index.html"))
  style_css_b64  = base64encode(file("${path.module}/web/style.css"))

  # User data runs at instance boot. It:
  # - installs Apache and EFS utilities
  # - starts Apache
  # - writes a /health file for ALB health checks
  # - writes your static site files
  # - mounts EFS to /mnt/efs (shared storage)
  user_data = <<-EOT
    #!/bin/bash
    set -e

    yum update -y
    yum install -y httpd || true

    # EFS utils may not be present on all AL2 AMIs by default; this makes boot more reliable
    yum install -y amazon-efs-utils || true

    systemctl enable httpd
    systemctl start httpd

    # Health check endpoint for the ALB target group
    echo "ok" > /var/www/html/health

    # Deploy static site files
    echo "${local.index_html_b64}" | base64 -d > /var/www/html/index.html
    echo "${local.style_css_b64}"  | base64 -d > /var/www/html/style.css

    # Mount EFS (shared storage)
    mkdir -p /mnt/efs

    # Use TLS if efs-utils is available; if not, mount -a won't break the instance boot
    echo "${aws_efs_file_system.this.id}:/ /mnt/efs efs _netdev,tls 0 0" >> /etc/fstab
    mount -a || true
  EOT
}

# ----------------------------
# Launch Template
# ----------------------------
resource "aws_launch_template" "app" {
  name_prefix   = "${var.name}-lt-"
  image_id      = data.aws_ssm_parameter.al2_ami.value
  instance_type = var.instance_type

  # Optional: only set key_name if you want SSH. For best practice, use SSM instead.
  key_name = var.key_name != "" ? var.key_name : null

  # IMPORTANT: This attaches the IAM instance profile so SSM works
  iam_instance_profile {
    name = aws_iam_instance_profile.app.name
  }

  vpc_security_group_ids = [aws_security_group.app.id]

  # user_data must be base64 for launch templates
  user_data = base64encode(local.user_data)

  tag_specifications {
    resource_type = "instance"
    tags          = merge(local.common_tags, { Name = "${var.name}-app" })
  }

  tags = merge(local.common_tags, { Name = "${var.name}-lt" })
}

# ----------------------------
# Auto Scaling Group
# ----------------------------
resource "aws_autoscaling_group" "app" {
  name = "${var.name}-asg"

  # private_app is a map because subnets were created with for_each
  vpc_zone_identifier = [for s in values(aws_subnet.private_app) : s.id]

  min_size         = var.asg_min
  max_size         = var.asg_max
  desired_capacity = var.asg_desired

  # Because we attach to an ALB target group, use ELB health checks
  health_check_type         = "ELB"
  health_check_grace_period = 120

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  # Attach instances to the ALB target group
  target_group_arns = [aws_lb_target_group.app.arn]

  # Tag instances launched by the ASG
  tag {
    key                 = "Name"
    value               = "${var.name}-app"
    propagate_at_launch = true
  }

  # Safer updates during changes
  lifecycle {
    create_before_destroy = true
  }

  # Ensure ALB listener exists before ASG tries to register targets
  depends_on = [aws_lb_listener.http]
}
