locals {
  pool_id = values.pool_id != "" ? values.pool_id : ""
  hostname = values.hostname
  password = values.password
}

unit "proxmox_pool" {
  // NOTE: Take note that this source here uses a Git URL instead of a local path.
  //
  // This is because units and stacks are generated
  // as shallow directories when consumed.
  //
  // Assume that a user consuming this stack will exclusively have access
  // to the directory this file is in, and nothing else in this repository.
  source = "git::git@github.com:abes140377/terragrunt-infrastructure-catalog-homelab.git//units/proxmox-pool?ref=${values.version}"
  path   = "proxmox-pool"

  values = {
    pool_id = values.pool_id
  }
}

unit "proxmox_lxc" {
  // NOTE: Take note that this source here uses a Git URL instead of a local path.
  //
  // This is because units and stacks are generated
  // as shallow directories when consumed.
  //
  // Assume that a user consuming this stack will exclusively have access
  // to the directory this file is in, and nothing else in this repository.
  source = "git::git@github.com:abes140377/terragrunt-infrastructure-catalog-homelab.git//units/proxmox-lxc?ref=${values.version}"
  path   = "proxmox-lxc"

  values = {
    hostname        = values.hostname
    password        = values.password
    pool_id         = values.pool_id
    pool_unit_path  = "../proxmox-pool"
  }
}

unit "dns" {
  // NOTE: Take note that this source here uses a Git URL instead of a local path.
  //
  // This is because units and stacks are generated
  // as shallow directories when consumed.
  //
  // Assume that a user consuming this stack will exclusively have access
  // to the directory this file is in, and nothing else in this repository.
  source = "git::git@github.com:abes140377/terragrunt-infrastructure-catalog-homelab.git//units/dns?ref=${values.version}"
  path   = "dns"

  values = {
    zone           = "home.sflab.io."
    name           = values.hostname
    dns_server     = "192.168.1.13"
    dns_port       = 5353
    key_name       = "ddnskey."
    key_algorithm  = "hmac-sha512"
    lxc_unit_path  = "../proxmox-lxc"
  }
}
