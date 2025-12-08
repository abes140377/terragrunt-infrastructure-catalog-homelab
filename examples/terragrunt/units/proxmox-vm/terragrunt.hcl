include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  provider_config    = read_terragrunt_config(find_in_parent_folders("provider-config.hcl"))

  proxmox_endpoint = "https://${local.provider_config.locals.proxmox_host}:${local.provider_config.locals.proxmox_port}/"
  proxmox_insecure = local.provider_config.locals.proxmox_insecure
}

# Generate Proxmox and Homelab provider blocks
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

provider "homelab" {}
EOF
}

terraform {
  source = "../../../.././/modules/proxmox-vm"
}

dependency "proxmox_pool" {
  config_path = "../proxmox-pool"

  mock_outputs = {
    pool_id = "mock-pool"
  }
}

inputs = {
  # Required inputs
  env = "dev"
  app = "terragrunt-vm"

  # Optional inputs
  # memory = 4096  # Customize memory allocation (default: 2048MB)
  # cores  = 4     # Customize CPU cores (default: 2)

  # Derived inputs
  pool_id = dependency.proxmox_pool.outputs.pool_id
  network_config = {
    type        = "static"
    ip_address  = "192.168.1.33"
    cidr        = 24
    gateway     = "192.168.1.1"
    # dns_servers = ["8.8.8.8", "8.8.4.4"]  # Optional
  }
}
