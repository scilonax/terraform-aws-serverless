resource "aws_s3_bucket" "lambdas" {
  bucket = "${var.domain}-lambdas"
  versioning {
    enabled = true
  }
}

data "aws_iam_role" "lambda" {
  name = var.lambda_role_name
}

data "aws_iam_policy_document" "dynamodb_lambda_policy" {
  count = length(var.dynamodb_tables_arn) == 0 ? 0 : 1
  statement {
    actions = [
      "dynamodb:*",
    ]

    resources = var.dynamodb_tables_arn
  }
}

resource "aws_iam_role_policy" "lambda" {
  count  = length(var.dynamodb_tables_arn) == 0 ? 0 : 1
  name   = var.domain
  role   = data.aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.dynamodb_lambda_policy[0].json
}
