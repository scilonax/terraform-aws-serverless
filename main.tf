data "aws_region" "current" {
}

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
    origin_id = var.cdn_origin_id

    custom_origin_config {
      http_port = 80
      https_port = 443
      origin_ssl_protocols = ["TLSv1"]
      origin_protocol_policy = "http-only"
    }
  }

  enabled = true
  is_ipv6_enabled = true
  default_root_object = "index.html"

  aliases = [var.domain]

  default_cache_behavior {
    allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods = ["GET", "HEAD"]
    target_origin_id = var.cdn_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl = 0
    default_ttl = 3600
    max_ttl = 86400
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  custom_error_response {
    error_code = "404"
    error_caching_min_ttl = "5"
    response_code = "404"
    response_page_path = "/404.html"
  }

  viewer_certificate {
    ssl_support_method = "sni-only"
    acm_certificate_arn = var.acm_certificate_arn
    minimum_protocol_version = "TLSv1"
  }
}

resource "aws_route53_record" "website_alias" {
  name = var.domain
  zone_id = var.route53_zone_id
  type = "A"

  alias {
    name = aws_cloudfront_distribution.website_cdn.domain_name
    zone_id = "Z2FDTNDATAQYW2"
    evaluate_target_health = false
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

resource "aws_cognito_user_pool" "website_auth" {
  name = var.domain
}

resource "aws_cognito_user_pool_client" "website_auth_client" {
  name = var.domain
  user_pool_id = aws_cognito_user_pool.website_auth.id
}

resource "aws_dynamodb_table" "tables" {
  count        = length(var.dynamodb_tables)
  name         = var.dynamodb_tables[count.index]
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = element(var.dynamodb_table_hash_keys, count.index)
  range_key    = element(var.dynamodb_table_range_keys, count.index)

  dynamic "attribute" {
    for_each = [var.dynamodb_table_attributes[count.index]]
    content {
      name = attribute.value.name
      type = attribute.value.type
    }
  }
}

data "aws_iam_policy_document" "dynamodb_lambda_policy" {
  statement {
    actions = [
      "dynamodb:*",
    ]

    resources = [
      aws_dynamodb_table.tables[0].arn,
    ]
  }
}

resource "aws_iam_role" "lambda" {
  name = var.domain

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "lambda" {
  name = var.domain
  role = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.dynamodb_lambda_policy.json
}

resource "aws_s3_bucket" "lambdas" {
  bucket = "${var.domain}-lambdas"
}

resource "aws_lambda_function" "lambdas" {
  count = length(var.lambdas)

  function_name = element(var.lambdas, count.index)
  role = aws_iam_role.lambda.arn
  handler = element(var.lambda_handlers, count.index)
  runtime = element(var.lambda_runtimes, count.index)
  publish = true
  s3_bucket = aws_s3_bucket.lambdas.id
  s3_key = "${element(var.lambdas, count.index)}/${element(var.lambda_versions, count.index)}/${element(var.lambdas, count.index)}.zip"

  depends_on = [
    aws_iam_role_policy_attachment.lambda_logs,
    aws_cloudwatch_log_group.lambdas,
    aws_s3_bucket_object.lambdas,
  ]
}

resource "aws_lambda_alias" "lambdas" {
  count = length(var.lambdas)

  name = element(var.lambdas, count.index)
  description = "prod"
  function_name = aws_lambda_function.lambdas[count.index].arn
  function_version = "$LATEST"
}

data "archive_file" "lambdas" {
  count = length(var.lambdas)
  type = "zip"
  source_file = element(var.lambda_files, count.index)
  output_path = "${element(var.lambdas, count.index)}.zip"
}

resource "aws_s3_bucket_object" "lambdas" {
  count = length(var.lambdas)

  bucket = aws_s3_bucket.lambdas.id
  key = "${element(var.lambdas, count.index)}/${element(var.lambda_versions, count.index)}/${element(var.lambdas, count.index)}.zip"
  source = data.archive_file.lambdas[count.index].output_path
  etag = filemd5(data.archive_file.lambdas[count.index].output_path)
}

resource "aws_lambda_permission" "lambdas" {
  count = length(var.lambda_apis)

  statement_id = "AllowExecutionFromAPIGateway"
  action = "lambda:InvokeFunction"
  function_name = var.lambda_apis[count.index]
  principal = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.apis[var.api_lambdas[count.index]].execution_arn}/*/*/*"
}

resource "aws_cloudwatch_log_group" "lambdas" {
  count = length(var.lambdas)
  name = "/aws/lambda/${element(var.lambdas, count.index)}"
  retention_in_days = 1
}

resource "aws_iam_policy" "lambda_logging" {
  name = "lambda_logging"
  path = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

resource "aws_api_gateway_rest_api" "apis" {
  count = length(var.api_versions)
  name  = "${var.domain}-${var.api_versions[count.index]}"
  body  = var.api_swaggers[count.index]
}

resource "aws_api_gateway_deployment" "green_versions" {
  count       = length(var.api_versions)
  rest_api_id = aws_api_gateway_rest_api.apis[count.index].id
  stage_name  = "green"
  variables = {
    deploy_number = var.api_green_deploy_numbers[count.index]
  }
}

resource "aws_api_gateway_deployment" "blue_versions" {
  count       = length(var.api_versions)
  rest_api_id = aws_api_gateway_rest_api.apis[count.index].id
  stage_name  = "blue"
  variables = {
    deploy_number = var.api_blue_deploy_numbers[count.index]
  }
}

resource "aws_api_gateway_domain_name" "api" {
  domain_name              = "api.${var.domain}"
  regional_certificate_arn = var.acm_certificate_arn

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_route53_record" "api" {
  name    = aws_api_gateway_domain_name.api.domain_name
  type    = "A"
  zone_id = var.route53_zone_id

  alias {
    evaluate_target_health = true
    name                   = aws_api_gateway_domain_name.api.regional_domain_name
    zone_id                = aws_api_gateway_domain_name.api.regional_zone_id
  }
}

resource "aws_api_gateway_base_path_mapping" "versions" {
  count       = length(var.api_versions)
  api_id      = aws_api_gateway_rest_api.apis[count.index].id
  stage_name  = var.api_stages[count.index]
  domain_name = aws_api_gateway_domain_name.api.domain_name
  base_path   = var.api_versions[count.index]
  depends_on = [
    aws_api_gateway_deployment.blue_versions,
    aws_api_gateway_deployment.green_versions,
  ]
}
