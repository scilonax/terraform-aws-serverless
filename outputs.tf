output "cdn_id" {
  value = aws_cloudfront_distribution.website_cdn.id
}

output "cdn_domain_name" {
  value = aws_cloudfront_distribution.website_cdn.domain_name
}
