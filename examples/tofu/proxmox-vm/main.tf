terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.69.0"
    }
    homelab = {
      source  = "registry.terraform.io/abes140377/homelab"
      version = ">= 0.2.0"
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

provider "homelab" {}

variable "env" {
  description = "The environment this VM belongs to (e.g., dev, staging, prod)."
  type        = string
}

variable "app" {
  description = "The application this VM belongs to (e.g., web, db, api)."
  type        = string
}

variable "pool_id" {
  description = "The ID of the Proxmox pool to which the virtual machine will be assigned."
  type        = string
  default     = ""
}

variable "network_config" {
  description = "The network configuration for the virtual machine."
  type = object({
    type        = string
    ip_address  = optional(string)
    cidr        = optional(number)
    gateway     = optional(string)
    dns_servers = optional(list(string), [])
  })
}

module "proxmox_vm" {
  source = "../../../modules/proxmox-vm"

  env                 = var.env
  app                 = var.app
  pool_id             = var.pool_id
  network_config      = var.network_config
  ssh_public_key_path = "${path.module}/../../../keys/admin_id_ecdsa.pub"
}
