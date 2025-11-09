locals {
  version = "feat/next"

  # pool configuration
  pool_id = "example-stack-pool"

  # container configuration
  hostname = "example-stack-container"
  password = "SecurePassword123!"

  zone = "home.sflab.io."
}

unit "proxmox_lxc_1" {
  source = "../../../../units/proxmox-lxc"

  path = "proxmox-lxc-1"

  values = {
    version = local.version

    hostname = "${local.hostname}-1"
    password = local.password
    pool_id  = local.pool_id
  }
}

unit "proxmox_lxc_2" {
  source = "../../../../units/proxmox-lxc"

  path = "proxmox-lxc-2"

  values = {
    version = local.version

    hostname = "${local.hostname}-2"
    password = local.password
    pool_id  = local.pool_id
  }
}

unit "dns_1" {
  source = "../../../../units/dns"

  path = "dns-1"

  values = {
    version = local.version

    name = "${local.hostname}-1"
    zone = local.zone

    compute_path = "../proxmox-lxc-1"
  }
}

unit "dns_2" {
  source = "../../../../units/dns"

  path = "dns-2"

  values = {
    version = local.version

    name = "${local.hostname}-2"
    zone = local.zone

    compute_path = "../proxmox-lxc-2"
  }
}
