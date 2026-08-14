data "archive_file" "lambda" {
  type        = "zip"
  source_file  = "${path.module}/../lambda/handler.py"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "ingest" {
  provider = aws.eu-west-1
  function_name = "${local.aws_config_env.project}-ingest"
  role          = aws_iam_role.lambda.arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.12"
  timeout       = 10
  memory_size   = 128

  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.measurements.name
      API_KEY    = aws_ssm_parameter.ingest_api_key.name
    }
  }

  tags = merge(local.tags, {
    Name = local.aws_config_env.name
  })
}

resource "aws_lambda_permission" "apigw" {
  provider = aws.eu-west-1
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ingest.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http.execution_arn}/*/*"
}