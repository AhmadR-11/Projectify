# ==============================================================================
# PROJECTIFY — TERRAFORM ROUTE 53 & ACM SSL CONFIGURATION
# ==============================================================================
#
# PURPOSE:
#   Provisions an AWS Route 53 DNS Hosted Zone and an AWS Certificate Manager (ACM)
#   SSL/TLS certificate for custom domain routing and HTTPS security.
# ==============================================================================

# Route 53 Hosted Zone for Custom Domain
resource "aws_route53_zone" "main" {
  count = var.domain_name != "" ? 1 : 0
  name  = var.domain_name

  tags = {
    Name = "${var.project_name}-dns-zone"
  }
}

# ACM SSL Certificate for Domain and Wildcard Subdomains (*.domain.com)
resource "aws_acm_certificate" "ssl" {
  count             = var.domain_name != "" ? 1 : 0
  domain_name       = var.domain_name
  validation_method = "DNS"

  subject_alternative_names = [
    "*.${var.domain_name}"
  ]

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.project_name}-ssl-cert"
  }
}

# Route 53 DNS Validation Record for ACM Certificate
resource "aws_route53_record" "cert_validation" {
  for_each = var.domain_name != "" ? {
    for dvo in aws_acm_certificate.ssl[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.main[0].zone_id
}

# Certificate Validation Resource
resource "aws_acm_certificate_validation" "ssl" {
  count                   = var.domain_name != "" ? 1 : 0
  certificate_arn         = aws_acm_certificate.ssl[0].arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}
