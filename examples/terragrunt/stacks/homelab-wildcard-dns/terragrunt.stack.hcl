locals {
  version = "main"
  pool_id = "wildcard-test-pool"
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

# Regular DNS record for direct access
unit "dns_regular" {
  source = "../../../../units/dns"
  path   = "dns-regular"

  values = {
    version      = local.version
    env          = local.env
    app          = local.app
    zone         = local.zone
    wildcard     = false
    compute_path = "../proxmox-lxc"
  }
}

# Wildcard DNS record for all subdomains
unit "dns_wildcard" {
  source = "../../../../units/dns"
  path   = "dns-wildcard"

  values = {
    version      = local.version
    env          = local.env
    app          = local.app
    zone         = local.zone
    wildcard     = true
    compute_path = "../proxmox-lxc"
  }
}
