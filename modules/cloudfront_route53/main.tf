resource "aws_route53_record" "website_alias" {
  name = var.domain
  zone_id = var.route53_zone_id
  type = "A"

  alias {
    name = var.cdn_domain_name
    zone_id = "Z2FDTNDATAQYW2"
    evaluate_target_health = false
  }
}