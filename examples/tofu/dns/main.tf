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
    port          = 5353
    key_name      = "ddnskey."
    key_algorithm = "hmac-sha512"
    key_secret    = var.dns_key_secret
  }
}

variable "dns_key_secret" {
  description = "The DNS key secret."
  type        = string
}

# Regular DNS record
module "dns_regular" {
  source = "../../../modules/dns"

  env       = "dev"
  app       = "test"
  zone      = "home.sflab.io."
  addresses = ["192.168.1.88"]
  wildcard  = false # Creates: dev-test.home.sflab.io
}

# Wildcard DNS record
module "dns_wildcard" {
  source = "../../../modules/dns"

  env       = "dev"
  app       = "wildcard"
  zone      = "home.sflab.io."
  addresses = ["192.168.1.99"]
  wildcard  = true # Creates: *.dev-wildcard.home.sflab.io
}

output "regular_fqdn" {
  description = "Generated FQDN"
  value       = module.dns_regular.fqdn
}

output "wildcard_fqdn" {
  description = "Wildcard DNS record FQDN"
  value       = module.dns_wildcard.fqdn
}
