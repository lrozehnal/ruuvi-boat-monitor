resource "aws_route53_zone" "zone" {
  name     = local.aws_config_env.name
  provider = aws.eu-west-1

  tags = merge(local.tags, {
    Name = local.aws_config_env.name
  })
}
