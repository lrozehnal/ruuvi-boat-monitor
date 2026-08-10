resource "aws_apigatewayv2_api" "http" {
  name          = "${local.aws_config_env.project}-api"
  provider     = aws.us-east-1
  protocol_type = "HTTP"

  tags = local.tags
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http.id  
  name        = "$default"
  provider     = aws.us-east-1
  auto_deploy = true
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.http.id
  provider     = aws.us-east-1
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.ingest.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "ingest" {
  provider     = aws.us-east-1
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "POST /ingest"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}