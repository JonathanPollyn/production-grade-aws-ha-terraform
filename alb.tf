# ==========================================================
# ALB (Internet-facing)
# ALB in public subnets across 2 AZs
# Forwards HTTP traffic to EC2 instances (ASG) in private subnets
# ==========================================================

resource "aws_lb" "this" {
  name               = "${var.name}-alb"
  load_balancer_type = "application"

  # Internet-facing ALB (public)
  internal        = false
  security_groups = [aws_security_group.alb.id]

  # public is a map (for_each), so use values()
  subnets = [for s in values(aws_subnet.public) : s.id]

  tags = merge(local.common_tags, { Name = "${var.name}-alb" })

  # Ensure networking is ready (optional safety)
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_lb_target_group" "app" {
  name        = "${var.name}-tg"
  port        = var.app_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.this.id
  target_type = "instance"

  # Health check matches your user_data writing /health
  health_check {
    enabled             = true
    path                = var.health_check_path
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = merge(local.common_tags, { Name = "${var.name}-tg" })
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
