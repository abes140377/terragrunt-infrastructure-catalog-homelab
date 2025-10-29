variable "hostname" {
  description = "The hostname of the LXC container."
  type        = string
}

variable "poolid" {
  description = "The ID of the Proxmox pool to which the LXC container will be assigned."
  type        = string
  default     = ""
}
