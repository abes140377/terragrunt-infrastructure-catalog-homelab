terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.69.0"
    }
  }
  required_version = ">= 1.9.0"
}

provider "proxmox" {
  endpoint = "https://proxmox.home.sflab.io:8006/"
  insecure = true

  ssh {
    agent = true
  }
}

variable "hostname" {
  description = "The hostname of the LXC container."
  type        = string
}

variable "pool_id" {
  description = "The ID of the Proxmox pool to which the LXC container will be assigned."
  type        = string
  default     = ""
}

module "proxmox_lxc" {
  source = "../../../modules/proxmox-lxc"

  hostname = var.hostname
  password = "StrongPassword!"
  pool_id  = var.pool_id
}
