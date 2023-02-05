variable "domain_name" {
  default     = "shoplikeaboss247.com"
  type        = string
  description = "Domain name"
}


resource "aws_route53_zone" "hosted_zone" {
  name = var.domain_name
  tags = {
    Environment = "dev"
  }
}

# Spin up a Route53 Record for the load balancer
resource "aws_route53_record" "site_domain" {
  zone_id = aws_route53_zone.hosted_zone.zone_id
  name    = "terraform-test.${var.domain_name}"
  type    = "A"
  alias {
    name                   = aws_lb.altschool-lb.dns_name
    zone_id                = aws_lb.altschool-lb.zone_id
    evaluate_target_health = true
  }
}
