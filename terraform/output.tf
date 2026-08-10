output "api_endpoint" {
  description = "API Gateway endpoint URL"
  value       = "${aws_apigatewayv2_api.http.api_endpoint}/ingest"
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.measurements.name
}

output "lambda_function_name" {
  value = aws_lambda_function.ingest.function_name
}