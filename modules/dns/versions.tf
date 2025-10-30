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
    server        = var.dns_server
    port          = var.dns_port
    key_name      = var.key_name
    key_algorithm = var.key_algorithm
    key_secret    = var.key_secret
  }
}
