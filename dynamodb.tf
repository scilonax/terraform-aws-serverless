//noinspection MissingProperty
resource "aws_dynamodb_table" "tables" {
  count        = length(var.dynamodb_tables)
  name         = var.dynamodb_tables[count.index].name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = var.dynamodb_tables[count.index].hash_key
  range_key    = var.dynamodb_tables[count.index].range_key

  dynamic "attribute" {
    for_each = [for a in var.dynamodb_tables[count.index].attributes: {
      name = a.name
      type = a.type
    }]
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
