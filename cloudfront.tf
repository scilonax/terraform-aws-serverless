resource "aws_s3_bucket" "website" {
  bucket = var.domain
  acl    = "public-read"

  policy = <<EOF
{
  "Id": "bucket_policy_site",
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "bucket_policy_site_main",
      "Action": [
        "s3:GetObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${var.domain}/*",
      "Principal": "*"
    }
  ]
}
EOF


  website {
    index_document = "index.html"
    error_document = "404.html"
  }
}

resource "aws_cloudfront_distribution" "website_cdn" {
  origin {
    domain_name = "${var.domain}.s3-website-${data.aws_region.current.name}.amazonaws.com"
    origin_id   = var.cdn_origin_id

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_ssl_protocols   = ["TLSv1"]
      origin_protocol_policy = "http-only"
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  aliases = concat([var.domain], var.domain_aliases)

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = var.cdn_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  custom_error_response {
    error_code            = "404"
    error_caching_min_ttl = "5"
    response_code         = "404"
    response_page_path    = "/404.html"
  }

  viewer_certificate {
    ssl_support_method       = "sni-only"
    acm_certificate_arn      = var.acm_certificate_arn
    minimum_protocol_version = "TLSv1"
  }
}

resource "null_resource" "deploy" {
  depends_on = [
    aws_s3_bucket.website,
    aws_cloudfront_distribution.website_cdn,
  ]
  provisioner "local-exec" {
    command = <<EOF
aws --profile ${var.aws_profile} s3 cp ${var.website_folder} s3://${aws_s3_bucket.website.id} --recursive --acl public-read
aws --profile ${var.aws_profile} cloudfront create-invalidation --distribution-id ${aws_cloudfront_distribution.website_cdn.id} --paths '/*'
EOF
  }
}
