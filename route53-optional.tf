# ==========================================================
# Route 53 (Optional)
# Purpose:
# - If enable_route53 = true, create a DNS record that points your domain to the ALB.
# Note:
# - This does NOT implement DNS failover because the architecture has only one ALB target.
# - ALB health is handled by target group health checks.
# ==========================================================

resource "aws_route53_record" "app" {
  count = var.enable_route53 ? 1 : 0

  zone_id = var.hosted_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.this.dns_name
    zone_id                = aws_lb.this.zone_id
    evaluate_target_health = true
  }
}
