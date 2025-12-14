data "homelab_naming" "this" {
  env = var.env
  app = var.app
}

resource "dns_a_record_set" "this" {
  zone      = var.zone
  name      = var.wildcard ? "*.${data.homelab_naming.this.name}" : data.homelab_naming.this.name
  addresses = var.addresses
  ttl       = var.ttl
}
