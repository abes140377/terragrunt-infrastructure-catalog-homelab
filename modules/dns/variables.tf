variable "zone" {
  description = "The DNS zone name (e.g., 'home.sflab.io.'). Must end with a dot."
  type        = string
}

variable "name" {
  description = "The DNS record name within the zone (e.g., 'server' for server.home.sflab.io)."
  type        = string
}

variable "addresses" {
  description = "List of IPv4 addresses for the A record."
  type        = list(string)
}

variable "ttl" {
  description = "Time-to-live for the DNS record in seconds."
  type        = number
  default     = 300
}

variable "dns_server" {
  description = "DNS server IPv4 address (e.g., '192.168.1.13')."
  type        = string
}

variable "dns_port" {
  description = "DNS server port for dynamic updates."
  type        = number
  default     = 53
}

variable "key_name" {
  description = "TSIG key name for authentication (e.g., 'terraform-key.')."
  type        = string
}

variable "key_algorithm" {
  description = "TSIG key algorithm (e.g., 'hmac-sha256')."
  type        = string
}

variable "key_secret" {
  description = "TSIG key secret for authentication."
  type        = string
  sensitive   = true
}
