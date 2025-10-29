variable "hostname" {
  description = "The hostname of the LXC container."
  type        = string
}

variable "password" {
  description = "The password for the root user of the LXC container."
  type        = string
  sensitive   = true
}

variable "poolid" {
  description = "The ID of the Proxmox pool to which the LXC container will be assigned."
  type        = string
  default     = ""
}
