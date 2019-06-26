resource "aws_s3_bucket" "website" {
  bucket = "${var.domain}"
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
    domain_name = "${var.domain}.s3-website-us-east-1.amazonaws.com"
    origin_id   = "${var.cdn_origin_id}"

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

  aliases = ["${var.domain}"]

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${var.cdn_origin_id}"

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
    acm_certificate_arn      = "${var.acm_certificate_arn}"
    minimum_protocol_version = "TLSv1"
  }
}

resource "aws_route53_record" "website_alias" {
  name    = "${var.domain}"
  zone_id = "${var.route53_zone_id}"
  type    = "A"

  alias {
    name                   = "${aws_cloudfront_distribution.website_cdn.domain_name}"
    zone_id                = "Z2FDTNDATAQYW2"
    evaluate_target_health = false
  }
}

resource "aws_cognito_user_pool" "website_auth" {
  name = "${var.domain}"
}

resource "aws_cognito_user_pool_client" "website_auth_client" {
  name = "${var.domain}"

  user_pool_id = "${aws_cognito_user_pool.website_auth.id}"
}

resource "aws_dynamodb_table" "tables" {
  count        = "${length(var.dynamodb_tables)}"
  name         = "${var.dynamodb_tables[count.index]}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "${element(var.dynamodb_table_hash_keys, count.index)}"
  range_key    = "${element(var.dynamodb_table_range_keys, count.index)}"

  attribute = ["${var.dynamodb_table_attributes[count.index]}"]
}

data "aws_iam_policy_document" "dynamodb_lambda_policy" {
  statement {
    actions = [
      "dynamodb:*",
    ]

    resources = [
      "${aws_dynamodb_table.tables.arn}",
    ]
  }
}

resource "aws_iam_role" "lambda" {
  name = "${var.domain}"

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
  name   = "${var.domain}"
  role   = "${aws_iam_role.lambda.id}"
  policy = "${data.aws_iam_policy_document.dynamodb_lambda_policy.json}"
}

resource "aws_s3_bucket" "lambdas" {
  bucket = "${var.domain}-lambdas"
}

resource "aws_lambda_function" "lambdas" {
  count = "${length(var.lambdas)}"

  function_name = "${element(var.lambdas, count.index)}"
  role          = "${aws_iam_role.lambda.arn}"
  handler       = "${element(var.lambda_handlers, count.index)}"
  runtime       = "${element(var.lambda_runtimes, count.index)}"

  s3_bucket = "${aws_s3_bucket.lambdas.id}"
  s3_key    = "${element(var.lambdas, count.index)}/${element(var.lambda_versions, count.index)}/${element(var.lambdas, count.index)}.zip"

  depends_on = ["aws_iam_role_policy_attachment.lambda_logs", "aws_cloudwatch_log_group.lambdas", "aws_s3_bucket_object.lambdas"]
}

data "archive_file" "lambdas" {
  count = "${length(var.lambdas)}"
  type        = "zip"
  source_file = "${element(var.lambda_files, count.index)}"
  output_path = "${path.module}/${element(var.lambdas, count.index)}.zip"
}

resource "aws_s3_bucket_object" "lambdas" {
  count = "${length(var.lambdas)}"

  bucket = "${aws_s3_bucket.lambdas.id}"
  key    = "${element(var.lambdas, count.index)}/${element(var.lambda_versions, count.index)}/${element(var.lambdas, count.index)}.zip"
  source = "${data.archive_file.lambdas.*.output_path[count.index]}"
  etag = "${md5(file(data.archive_file.lambdas.*.output_path[count.index]))}"
}

resource "aws_lambda_permission" "lambdas" {
  count = "${length(var.lambdas)}"

  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "${element(var.lambdas, count.index)}"
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*/*"
}

resource "aws_cloudwatch_log_group" "lambdas" {
  count             = "${length(var.lambdas)}"
  name              = "/aws/lambda/${element(var.lambdas, count.index)}"
  retention_in_days = 1
}

resource "aws_iam_policy" "lambda_logging" {
  name        = "lambda_logging"
  path        = "/"
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
  role       = "${aws_iam_role.lambda.name}"
  policy_arn = "${aws_iam_policy.lambda_logging.arn}"
}

resource "aws_api_gateway_rest_api" "api" {
  name = "${var.domain}"
  body = "${var.api_swagger}"
}

resource "aws_api_gateway_deployment" "prod" {
  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
  stage_name  = "prod"

  variables {
    api_swagger_hash = "${base64sha256(file("swagger.yaml"))}"
  }
}
