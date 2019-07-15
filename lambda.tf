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

  function_name = var.lambdas[count.index].name
  role = aws_iam_role.lambda.arn
  handler = var.lambdas[count.index].handler
  runtime = var.lambdas[count.index].runtime
  publish = true
  s3_bucket = aws_s3_bucket.lambdas.id
  s3_key = "${var.lambdas[count.index].name}/${var.lambdas[count.index].version}/${var.lambdas[count.index].name}.zip"

  depends_on = [
    aws_iam_role_policy_attachment.lambda_logs,
    aws_cloudwatch_log_group.lambdas,
    aws_s3_bucket_object.lambdas,
  ]
}

resource "aws_lambda_alias" "lambdas" {
  count = length(var.lambdas)

  name = var.lambdas[count.index].name
  description = "prod"
  function_name = aws_lambda_function.lambdas[count.index].arn
  function_version = "$LATEST"
}

data "archive_file" "lambdas" {
  count = length(var.lambdas)
  type = "zip"
  source_file = var.lambdas[count.index].file
  output_path = "${var.lambdas[count.index].name}.zip"
}

resource "aws_s3_bucket_object" "lambdas" {
  count = length(var.lambdas)

  bucket = aws_s3_bucket.lambdas.id
  key = "${var.lambdas[count.index].name}/${var.lambdas[count.index].version}/${var.lambdas[count.index].name}.zip"
  source = data.archive_file.lambdas[count.index].output_path
  etag = filemd5(data.archive_file.lambdas[count.index].output_path)
}

resource "aws_lambda_permission" "lambdas" {
  count = length(var.api_lambda_permissions)

  statement_id = "AllowExecutionFromAPIGateway"
  action = "lambda:InvokeFunction"
  function_name = var.api_lambda_permissions[count.index].lambda
  principal = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.apis[var.api_lambda_permissions[count.index].api_index].execution_arn}/*/*/*"
}

resource "aws_cloudwatch_log_group" "lambdas" {
  count = length(var.lambdas)
  name = "/aws/lambda/${var.lambdas[count.index].name}"
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
