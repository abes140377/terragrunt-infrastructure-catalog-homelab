output "fqdn" {
  description = "Fully qualified domain name of the normal DNS record. Null if normal record is not created."
  value       = length(dns_a_record_set.normal) > 0 ? "${dns_a_record_set.normal[0].name}.${dns_a_record_set.normal[0].zone}" : null
}

output "fqdn_wildcard" {
  description = "Fully qualified domain name of the wildcard DNS record. Null if wildcard record is not created."
  value       = length(dns_a_record_set.wildcard) > 0 ? "${dns_a_record_set.wildcard[0].name}.${dns_a_record_set.wildcard[0].zone}" : null
}

output "addresses" {
  description = "IP addresses assigned to the DNS records."
  value       = var.addresses
}
