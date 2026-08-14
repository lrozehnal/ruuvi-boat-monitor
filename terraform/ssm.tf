resource "aws_ssm_parameter" "ingest_api_key" {
  provider  = aws.eu-west-1
  name      = "/ruuvi-boat/ingest_api_key"
  type      = "SecureString"
  value     = var.ingest_api_key
  overwrite = true

  tags = local.tags
}