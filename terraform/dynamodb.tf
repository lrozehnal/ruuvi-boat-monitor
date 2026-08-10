resource "aws_dynamodb_table" "measurements" {
  name         = "${local.aws_config_env.project}-measurements"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "pk"
  range_key    = "sk"
  provider     = aws.us-east-1

  attribute {
    name = "pk"
    type = "S"
  }

  attribute {
    name = "sk"
    type = "S"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  tags = merge(local.tags, {
    Name    = local.aws_config_env.name
    Project = local.aws_config_env.project
  })
}