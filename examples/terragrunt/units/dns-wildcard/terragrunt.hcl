include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  dns_config = read_terragrunt_config(find_in_parent_folders("dns-config.hcl"))

  dns_server    = "${local.dns_config.locals.dns_server}"
  dns_port      = "${local.dns_config.locals.dns_port}"
  key_name      = "${local.dns_config.locals.key_name}"
  key_algorithm = "${local.dns_config.locals.key_algorithm}"
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "dns" {
  update {
    server        = "${local.dns_server}"
    port          = "${local.dns_port}"
    key_name      = "${local.key_name}"
    key_algorithm = "${local.key_algorithm}"
    key_secret    = "${get_env("TF_VAR_dns_key_secret", "mock-secret-for-testing")}"
  }
}
EOF
}

terraform {
  source = "../../../.././/modules/dns"
}

inputs = {
  # Wildcard DNS record example
  env       = "dev"
  app       = "example"
  zone      = "home.sflab.io."
  addresses = ["192.168.1.200"]
  ttl       = 300
  record_types = {
    normal   = false
    wildcard = true
  }
  # Creates: *.dev-example.home.sflab.io
}
