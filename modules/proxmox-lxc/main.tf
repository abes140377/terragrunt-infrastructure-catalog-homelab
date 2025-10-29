resource "proxmox_lxc" "this" {
  target_node  = "pve1"
  hostname     = var.hostname
  ostemplate   = "local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
  password     = "password"
  unprivileged = true
  pool         = var.poolid

  // Terraform will crash without rootfs defined
  rootfs {
    storage = "local-lvm"
    size    = "8G"
  }

  network {
    name   = "eth0"
    bridge = "vmbr0"
    ip     = "dhcp"
  }
}
