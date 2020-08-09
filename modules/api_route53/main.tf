resource "aws_route53_record" "api" {
  name    = var.domain_name
  type    = "A"
  zone_id = var.zone_id

  alias {
    evaluate_target_health = true
    name                   = var.regional_domain_name
    zone_id                = var.regional_zone_id
  }
}