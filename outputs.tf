output "function_name" {
  description = "Name of the Lambda function."

  value = aws_lambda_function.visitorCount.function_name
}

output "base_url" {
  description = "Base URL for API Gateway stage."

  value = aws_apigatewayv2_stage.visitorCountApiGateway.invoke_url
}

output "dynamodb_table_arn" {
description = "visitcount dynamodb table arn value."

  value = aws_dynamodb_table.visitCount.arn
}