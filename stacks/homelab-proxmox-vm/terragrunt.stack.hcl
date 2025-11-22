locals {
  pool_id = values.pool_id != "" ? values.pool_id : ""

  env    = values.env
  app    = values.app
  memory = try(values.memory, 2048)
  cores  = try(values.cores, 2)

  zone = try(values.dns_zone, "home.sflab.io.")
}

unit "proxmox_pool" {
  source = "git::git@github.com:abes140377/terragrunt-infrastructure-catalog-homelab.git//units/proxmox-pool?ref=${values.version}"

  path = "proxmox-pool"

  values = {
    version = values.version

    pool_id = local.pool_id
  }
}

unit "proxmox_vm" {
  source = "git::git@github.com:abes140377/terragrunt-infrastructure-catalog-homelab.git//units/proxmox-vm?ref=${values.version}"

  path = "proxmox-vm"

  values = {
    version = values.version

    env     = local.env
    app     = local.app
    memory  = local.memory
    cores   = local.cores
    pool_id = local.pool_id
  }
}

unit "dns" {
  source = "git::git@github.com:abes140377/terragrunt-infrastructure-catalog-homelab.git//units/dns?ref=${values.version}"

  path = "dns"

  values = {
    zone = local.zone
    name = "${local.env}-${local.app}"

    compute_path = "../proxmox-vm"
  }
}
