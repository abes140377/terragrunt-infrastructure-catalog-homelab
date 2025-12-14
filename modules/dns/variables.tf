variable "env" {
  description = "The environment this VM belongs to (e.g., dev, staging, prod)."
  type        = string
}

variable "app" {
  description = "The application this VM belongs to (e.g., web, db, api)."
  type        = string
}

variable "wildcard" {
  description = "Enable wildcard DNS record. When true, creates *.{env}-{app} record instead of {env}-{app}."
  type        = bool
  default     = false
}

variable "zone" {
  description = "The DNS zone name (e.g., 'home.sflab.io.'). Must end with a dot."
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
