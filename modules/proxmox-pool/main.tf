resource "proxmox_virtual_environment_pool" "this" {
  pool_id = var.poolid
  comment = var.description
}
