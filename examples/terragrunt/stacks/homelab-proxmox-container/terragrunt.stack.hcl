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
  source = "../../../../units/proxmox-pool"
  path   = "proxmox-pool"

  values = {
    version = "feat/next"

    pool_id = local.pool_id
  }
}

unit "proxmox_lxc" {
  source = "../../../../units/proxmox-lxc"
  path   = "proxmox-lxc"

  values = {
    version = "feat/next"

    hostname        = local.hostname
    password        = local.password
    pool_id         = local.pool_id

    pool_unit_path  = "../proxmox-pool"
  }
}

unit "dns" {
  source = "../../../../units/dns"
  path   = "dns"

  values = {
    version = "feat/next"

    name          = local.hostname
    zone          = local.zone
    dns_server    = local.dns_server
    dns_port      = local.dns_port
    key_name      = local.key_name
    key_algorithm = local.key_algorithm

    compute_path = "../proxmox-lxc"
  }
}
