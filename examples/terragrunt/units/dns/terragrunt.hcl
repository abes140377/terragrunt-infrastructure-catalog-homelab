include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  dns_config_vars = read_terragrunt_config(find_in_parent_folders("dns-config.hcl"))

  dns_server    = "${local.dns_config_vars.locals.dns_server}"
  dns_port      = "${local.dns_config_vars.locals.dns_port}"
  key_name      = "${local.dns_config_vars.locals.key_name}"
  key_algorithm = "${local.dns_config_vars.locals.key_algorithm}"
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
  // This double-slash allows the module to leverage relative paths to other modules in this repository.
  //
  // NOTE: When used in a different repository, you will need to
  // use a source URL that points to the relevant module in this repository.
  // e.g.
  // source = "git::git@github.com:abes140377/terragrunt-infrastructure-catalog-homelab.git//modules/dns"

  source = "../../../.././/modules/dns"
}

inputs = {
  zone      = "home.sflab.io."
  name      = "example-dns-record"
  addresses = ["192.168.1.100"]
  ttl       = 300
}
