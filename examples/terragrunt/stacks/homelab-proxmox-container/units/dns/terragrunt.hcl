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

# Generate DNS provider block
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "dns" {
  update {
    server        = "${values.dns_server}"
    port          = "${local.dns_port}"
    key_name      = "${values.key_name}"
    key_algorithm = "${values.key_algorithm}"
    key_secret    = "${get_env("TF_VAR_dns_key_secret", "mock-secret-for-testing")}"
  }
}
EOF
}

terraform {
  source = "../../../../../.././/modules/dns"
}

dependency "proxmox_lxc" {
  config_path = try(values.lxc_unit_path, "../proxmox-lxc")

  mock_outputs = {
    ipv4 = "192.168.1.100"
  }
}

inputs = {
  zone      = values.zone
  name      = values.name
  addresses = [dependency.proxmox_lxc.outputs.ipv4]
  ttl       = try(values.ttl, 300)
}
