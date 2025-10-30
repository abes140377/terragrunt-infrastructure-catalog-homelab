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
