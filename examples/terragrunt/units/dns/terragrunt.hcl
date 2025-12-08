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

# Generate DNS provider block with TSIG configuration
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
  zone      = "home.sflab.io."
  name      = "example-dns-record"
  addresses = ["192.168.1.100"]
  ttl       = 300
}
