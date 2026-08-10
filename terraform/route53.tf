resource "aws_route53_zone" "mplexia_com" {
  name     = local.aws_config_env.name
  provider = aws.us-east-1

  tags = merge(local.tags, {
    Name = local.aws_config_env.name
  })
}
