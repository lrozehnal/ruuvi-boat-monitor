locals {
  aws_config_env = yamldecode(file("../terraform-config/config.yaml"))
  tags = {
    terraform = "yes"
    github    = "https://github.com/lrozehnal/https://github.com/lrozehnal/ruuvi-boat-monitor"
  }
}

