resource "proxmox_pool" "this" {
  poolid  = var.poolid
  comment = var.description
}
