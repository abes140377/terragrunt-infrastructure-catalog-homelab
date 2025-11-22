locals {
  version = "main"

  # pool configuration
  pool_id = "example-stack-pool"
}

unit "proxmox_pool" {
  source = "../../../../units/proxmox-pool"

  path = "proxmox-pool"

  values = {
    version = local.version

    pool_id = local.pool_id
  }
}
