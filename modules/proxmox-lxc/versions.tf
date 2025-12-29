terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.69.0"
    }
    homelab = {
      source  = "registry.terraform.io/sflab-io/homelab"
      version = ">= 0.2.0"
    }
  }
  required_version = ">= 1.9.0"
}
