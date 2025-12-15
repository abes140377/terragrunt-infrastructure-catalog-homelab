locals {
  version = "main"
  pool_id = "example-stack-pool"
  env     = "dev"
  app     = "wc-test"
  password = "SecurePassword123!"
  zone    = "home.sflab.io."
}

unit "proxmox_lxc" {
  source = "../../../../units/proxmox-lxc"
  path   = "proxmox-lxc"

  values = {
    version  = local.version
    env      = local.env
    app      = local.app
    password = local.password
    pool_id  = local.pool_id
  }
}

# DNS records - creates both normal and wildcard records
unit "dns" {
  source = "../../../../units/dns"
  path   = "dns"

  values = {
    version      = local.version
    env          = local.env
    app          = local.app
    zone         = local.zone
    record_types = {
      normal   = true
      wildcard = true
    }
    compute_path = "../proxmox-lxc"
  }
}
