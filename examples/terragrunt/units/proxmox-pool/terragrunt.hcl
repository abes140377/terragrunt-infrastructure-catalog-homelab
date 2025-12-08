include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  provider_config = read_terragrunt_config(find_in_parent_folders("provider-config.hcl"))

  proxmox_endpoint = "https://${local.provider_config.locals.proxmox_host}:${local.provider_config.locals.proxmox_port}/"
  proxmox_insecure = local.provider_config.locals.proxmox_insecure
}

# Generate Proxmox provider block
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "proxmox" {
  endpoint  = "${local.proxmox_endpoint}"
  insecure  = ${local.proxmox_insecure}

  ssh {
    agent = true
  }
}
EOF
}

terraform {
  source = "../../../.././/modules/proxmox-pool"
}

inputs = {
  # Required inputs
  pool_id = "example-pool"
}
