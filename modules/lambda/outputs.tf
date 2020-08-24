output "invoke_arn" {
  value = aws_lambda_alias.lambda.invoke_arn
}

output "arn" {
  value = aws_lambda_alias.lambda.arn
}

output "role_name" {
  value = aws_iam_role.lambda.name
}
