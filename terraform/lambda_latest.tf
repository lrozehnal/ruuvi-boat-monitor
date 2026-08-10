data "archive_file" "lambda_latest" {
  type        = "zip"
  source_file = "${path.module}/../lambda/latest_handler.py"
  output_path = "${path.module}/lambda_latest.zip"
}

resource "aws_lambda_function" "latest" {
  provider      = aws.eu-west-1  # uprav podle sebe
  function_name = "${local.aws_config_env.project}-latest"
  role          = aws_iam_role.lambda.arn
  handler       = "latest_handler.lambda_handler"
  runtime       = "python3.12"
  timeout       = 10
  memory_size   = 128

  filename         = data.archive_file.lambda_latest.output_path
  source_code_hash = data.archive_file.lambda_latest.output_base64sha256

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.measurements.name
    }
  }
}

resource "aws_lambda_permission" "apigw_latest" {
  provider      = aws.eu-west-1
  statement_id  = "AllowAPIGatewayInvokeLatest"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.latest.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http.execution_arn}/*/*"
}

resource "aws_apigatewayv2_integration" "lambda_latest" {
  provider               = aws.eu-west-1
  api_id                 = aws_apigatewayv2_api.http.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.latest.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "latest" {
  provider  = aws.eu-west-1
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "GET /latest"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_latest.id}"
}

output "latest_endpoint" {
  value = "${aws_apigatewayv2_api.http.api_endpoint}/latest"
}