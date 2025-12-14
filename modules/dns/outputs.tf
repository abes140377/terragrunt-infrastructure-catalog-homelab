output "fqdn" {
  description = "Fully qualified domain name of the DNS record."
  value       = "${dns_a_record_set.this.name}.${dns_a_record_set.this.zone}"
}

output "addresses" {
  description = "IP addresses assigned to the DNS record."
  value       = dns_a_record_set.this.addresses
}
