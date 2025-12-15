data "homelab_naming" "this" {
  env = var.env
  app = var.app
}

resource "dns_a_record_set" "normal" {
  count = var.record_types.normal ? 1 : 0

  zone      = var.zone
  name      = data.homelab_naming.this.name
  addresses = var.addresses
  ttl       = var.ttl
}

resource "dns_a_record_set" "wildcard" {
  count = var.record_types.wildcard ? 1 : 0

  zone      = var.zone
  name      = "*.${data.homelab_naming.this.name}"
  addresses = var.addresses
  ttl       = var.ttl
}
