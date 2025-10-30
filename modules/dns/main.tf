resource "dns_a_record_set" "this" {
  zone      = var.zone
  name      = var.name
  addresses = var.addresses
  ttl       = var.ttl
}
