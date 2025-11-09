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

variable "vm_name" {
  description = "The name of the virtual machine."
  type        = string
}

variable "pool_id" {
  description = "The ID of the Proxmox pool to which the virtual machine will be assigned."
  type        = string
  default     = ""
}

module "proxmox_vm" {
  source = "../../../modules/proxmox-vm"

  vm_name = var.vm_name
  pool_id = var.pool_id
}
