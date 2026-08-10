resource "aws_iam_role" "lambda" {
  name     = "${local.aws_config_env.project}-lambda-role"
  provider = aws.eu-west-1

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  tags = local.tags
}


resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  provider   = aws.eu-west-1
}

resource "aws_iam_role_policy" "lambda_dynamodb" {
  name = "${local.aws_config_env.project}-lambda-dynamodb"
  role = aws_iam_role.lambda.id
  provider   = aws.eu-west-1

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:GetItem",
        "dynamodb:Query"
      ]
      Resource = [
        aws_dynamodb_table.measurements.arn,
        "${aws_dynamodb_table.measurements.arn}/index/*"
      ]
    }]
  })
}