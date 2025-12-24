terraform {
  required_providers {
    dns = {
      source  = "hashicorp/dns"
      version = ">= 3.4.0"
    }
    homelab = {
      source  = "registry.terraform.io/abes140377/homelab"
      version = ">= 0.2.0"
    }
  }
  required_version = ">= 1.9.0"
}
