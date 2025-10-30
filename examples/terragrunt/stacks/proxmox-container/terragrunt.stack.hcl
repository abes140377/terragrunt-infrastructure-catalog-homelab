locals {
  poolid   = "example-pool"
  hostname = "example-stack-container"
  password = "SecurePassword123!"
}

unit "proxmox_pool" {
  // Using local units with relative paths for testing
  // In production, use: git::git@github.com:abes140377/terragrunt-infrastructure-catalog-homelab.git//units/proxmox-pool?ref=v1.0.0
  source = "./units/proxmox-pool"
  path   = "proxmox-pool"

  values = {
    poolid = local.poolid
  }
}

unit "proxmox_lxc" {
  // Using local units with relative paths for testing
  // In production, use: git::git@github.com:abes140377/terragrunt-infrastructure-catalog-homelab.git//units/proxmox-lxc?ref=v1.0.0
  source = "./units/proxmox-lxc"
  path   = "proxmox-lxc"

  values = {
    hostname        = local.hostname
    password        = local.password
    poolid          = local.poolid
    pool_unit_path  = "../proxmox-pool"
  }
}
