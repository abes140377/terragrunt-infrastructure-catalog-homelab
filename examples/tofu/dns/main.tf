terraform {
  required_providers {
    dns = {
      source  = "hashicorp/dns"
      version = ">= 3.4.0"
    }
  }
  required_version = ">= 1.9.0"
}

provider "dns" {
  update {
    server        = "192.168.1.13"
    port          = 53
    key_name      = "ddnskey."
    key_algorithm = "hmac-sha256"
    key_secret    = var.dns_key_secret
  }
}

variable "dns_key_secret" {
  description = "The DNS key secret."
  type        = string
}

module "dns" {
  source = "../../../modules/dns"

  zone      = "home.sflab.io."
  name      = "test"
  addresses = ["192.168.1.88"]
}

# output "name" {
#   description = "Generated name"
#   value       = module.proxmox_pool.pool_id
# }
