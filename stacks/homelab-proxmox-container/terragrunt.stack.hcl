locals {
  pool_id = values.pool_id != "" ? values.pool_id : ""

  env      = values.env
  app      = values.app

  password = values.password

  zone = try(values.dns_zone, "home.sflab.io.")
}

unit "proxmox_pool" {
  source = "git::git@github.com:sflab-io/terragrunt-infrastructure-catalog-homelab.git//units/proxmox-pool?ref=${values.version}"

  path = "proxmox-pool"

  values = {
    version = values.version

    pool_id = local.pool_id
  }
}

unit "proxmox_lxc" {
  source = "git::git@github.com:sflab-io/terragrunt-infrastructure-catalog-homelab.git//units/proxmox-lxc?ref=${values.version}"

  path = "proxmox-lxc"

  values = {
    version = values.version

    env      = local.env
    app      = local.app
    password = local.password
    pool_id  = local.pool_id
  }
}

unit "dns" {
  source = "git::git@github.com:sflab-io/terragrunt-infrastructure-catalog-homelab.git//units/dns?ref=${values.version}"

  path = "dns"

  values = {
    version = values.version

    name = "${local.env}-${local.app}"
    zone = local.zone

    compute_path = "../proxmox-lxc"
  }
}
