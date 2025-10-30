resource "proxmox_virtual_environment_pool" "this" {
  pool_id = var.pool_id
  comment = var.description
}
