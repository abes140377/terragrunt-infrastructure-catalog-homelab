variable "env" {
  description = "The environment this VM belongs to (e.g., dev, staging, prod)."
  type        = string
}

variable "app" {
  description = "The application this VM belongs to (e.g., web, db, api)."
  type        = string
}

variable "record_types" {
  description = "Controls which DNS record types to create. Set 'normal' to true for standard {env}-{app} record, 'wildcard' to true for *.{env}-{app} record. Both can be true simultaneously."
  type = object({
    normal   = bool
    wildcard = bool
  })
  default = {
    normal   = true
    wildcard = false
  }

  validation {
    condition     = var.record_types.normal || var.record_types.wildcard
    error_message = "At least one record type (normal or wildcard) must be enabled."
  }
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
