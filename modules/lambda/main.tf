data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = var.source_dir
  output_path = "${path.module}/${var.function_name}.zip"
}

resource "aws_s3_bucket_object" "lambda" {
  bucket = var.bucket
  key    = "lambdas/${var.function_name}/${var.function_version}/${var.function_name}.zip"
  source = data.archive_file.lambda.output_path
  etag   = filemd5(data.archive_file.lambda.output_path)
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.retention_in_days
}

resource "aws_iam_role" "lambda" {
  name = var.function_name

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

data "aws_iam_policy" "lambda_basic" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = data.aws_iam_policy.lambda_basic.arn
}

resource "aws_lambda_function" "lambda" {
  function_name     = var.function_name
  role              = aws_iam_role.lambda.arn
  handler           = var.handler
  s3_bucket         = var.bucket
  s3_key            = aws_s3_bucket_object.lambda.key
  s3_object_version = aws_s3_bucket_object.lambda.version_id
  layers            = var.layers_arn
  runtime           = var.runtime
  environment {
    variables = var.env_variables
  }
  publish     = true
  timeout     = var.timeout
  depends_on  = [aws_cloudwatch_log_group.lambda]
  memory_size = var.memory_size
}

resource "aws_lambda_permission" "lambda" {
  count         = var.api_execution_arn == "" ? 0 : 1
  statement_id  = "AllowAPIInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  qualifier     = "prod"
  principal     = "apigateway.amazonaws.com"

  # The /*/*/* part allows invocation from any stage, method and resource path
  # within API Gateway REST API.
  # tflint-ignore: aws_lambda_permission_invalid_source_arn
  source_arn = "${var.api_execution_arn}/*/*/*"
}

resource "aws_lambda_alias" "lambda" {
  name             = "prod"
  function_name    = aws_lambda_function.lambda.arn
  function_version = "$LATEST"
}
