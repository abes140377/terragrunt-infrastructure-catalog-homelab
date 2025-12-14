locals {
  version = "main"

  # pool configuration
  pool_id = "example-stack-pool"

  # container configuration
  env      = "dev"
  app      = "example"
  password = "SecurePassword123!"

  zone = "home.sflab.io."
}

unit "proxmox_lxc_1" {
  source = "../../../../units/proxmox-lxc"

  path = "proxmox-lxc-1"

  values = {
    version = local.version

    env      = local.env
    app      = "${local.app}-1"
    password = local.password
    pool_id  = local.pool_id
  }
}

unit "proxmox_lxc_2" {
  source = "../../../../units/proxmox-lxc"

  path = "proxmox-lxc-2"

  values = {
    version = local.version

    env      = local.env
    app      = "${local.app}-2"
    password = local.password
    pool_id  = local.pool_id
  }
}

unit "dns_1" {
  source = "../../../../units/dns"

  path = "dns-1"

  values = {
    version = local.version

    env  = local.env
    app  = "${local.app}-1"
    zone = local.zone

    compute_path = "../proxmox-lxc-1"
  }
}

unit "dns_2" {
  source = "../../../../units/dns"

  path = "dns-2"

  values = {
    version = local.version

    env  = local.env
    app  = "${local.app}-2"
    zone = local.zone

    compute_path = "../proxmox-lxc-2"
  }
}
