locals {
  pool_id  = "example-stack-container-pool"

  hostname = "example-stack-container"
  password = "SecurePassword123!"

  zone          = "home.sflab.io."
  dns_server    = "192.168.1.13"
  dns_port      = 5353
  key_name      = "ddnskey."
  key_algorithm = "hmac-sha512"
}

unit "proxmox_pool" {
  // Using local units with relative paths for testing
  // In production, use: git::git@github.com:abes140377/terragrunt-infrastructure-catalog-homelab.git//units/proxmox-pool?ref=v1.0.0
  source = "./units/proxmox-pool"
  path   = "proxmox-pool"

  values = {
    pool_id = local.pool_id
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
    pool_id         = local.pool_id

    pool_unit_path  = "../proxmox-pool"
  }
}

unit "dns" {
  // Using local units with relative paths for testing
  // In production, use: git::git@github.com:abes140377/terragrunt-infrastructure-catalog-homelab.git//units/dns?ref=v1.0.0
  source = "./units/dns"
  path   = "dns"

  values = {
    name           = local.hostname
    zone           = local.zone
    dns_server     = local.dns_server
    dns_port       = local.dns_port
    key_name       = local.key_name
    key_algorithm  = local.key_algorithm

    lxc_unit_path  = "../proxmox-lxc"
  }
}
