output "ipv4" {
  description = "The IPv4 address of the LXC container."
  value       = proxmox_lxc.this.network.0.ip
}
